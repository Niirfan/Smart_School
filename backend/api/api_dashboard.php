<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$student_id = isset($_GET['student_id']) ? $_GET['student_id'] : (isset($_POST['student_id']) ? $_POST['student_id'] : 'S001');

// 1. ดึงข้อมูลนักเรียน
$stmt = $conn->prepare("SELECT * FROM students WHERE student_id = ?");
$stmt->bind_param("s", $student_id);
$stmt->execute();
$student_res = $stmt->get_result();

if ($student_res->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'ไม่พบข้อมูลนักเรียนรหัส ' . $student_id
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

$student = $student_res->fetch_assoc();

// 2. ดึงข้อมูลครูที่ปรึกษา (สุ่มหรือเลือกครูประจำการคนแรก)
$teacher_res = $conn->query("SELECT * FROM teachers ORDER BY teacher_id ASC LIMIT 1");
$teacher = ($teacher_res && $teacher_res->num_rows > 0) ? $teacher_res->fetch_assoc() : null;

// 3. คำนวณ GPAX จากตาราง grades + subjects
$grade_stmt = $conn->prepare("
    SELECT g.grade_result, s.credit 
    FROM grades g 
    JOIN subjects s ON g.subject_id = s.subject_id 
    WHERE g.student_id = ?
");
$grade_stmt->bind_param("s", $student_id);
$grade_stmt->execute();
$grade_res = $grade_stmt->get_result();

$total_credits = 0;
$total_points = 0;
while ($row = $grade_res->fetch_assoc()) {
    $c = floatval($row['credit']);
    $g = floatval($row['grade_result']);
    $total_credits += $c;
    $total_points += ($g * $c);
}
$gpax = $total_credits > 0 ? round($total_points / $total_credits, 2) : 3.78;

// 4. สถิติการมาเรียน (daily_attendance)
$att_stmt = $conn->prepare("
    SELECT daily_status, COUNT(*) as count 
    FROM daily_attendance 
    WHERE student_id = ? 
    GROUP BY daily_status
");
$att_stmt->bind_param("s", $student_id);
$att_stmt->execute();
$att_res = $att_stmt->get_result();

$present = 0;
$late = 0;
$leave = 0;
$absent = 0;

while ($r = $att_res->fetch_assoc()) {
    if ($r['daily_status'] === 'มาเรียน') $present = intval($r['count']);
    else if ($r['daily_status'] === 'มาสาย') $late = intval($r['count']);
    else if ($r['daily_status'] === 'ลา') $leave = intval($r['count']);
    else if ($r['daily_status'] === 'ขาด') $absent = intval($r['count']);
}

$total_days = $present + $late + $leave + $absent;
$att_percentage = $total_days > 0 ? round((($present + $late) / $total_days) * 100, 1) : 96.6;

// 5. คะแนนความประพฤติ (behaviors)
$beh_sum_stmt = $conn->prepare("SELECT SUM(score_change) as total_change FROM behaviors WHERE student_id = ?");
$beh_sum_stmt->bind_param("s", $student_id);
$beh_sum_stmt->execute();
$beh_sum_res = $beh_sum_stmt->get_result()->fetch_assoc();
$score_change = $beh_sum_res['total_change'] !== null ? intval($beh_sum_res['total_change']) : 0;
$current_conduct_score = max(0, min(100, 100 + $score_change));

// รายการความประพฤติล่าสุด
$beh_list_stmt = $conn->prepare("
    SELECT b.score_change, b.reason, b.created_at, t.name as teacher_name 
    FROM behaviors b 
    LEFT JOIN teachers t ON b.teacher_id = t.teacher_id 
    WHERE b.student_id = ? 
    ORDER BY b.created_at DESC 
    LIMIT 5
");
$beh_list_stmt->bind_param("s", $student_id);
$beh_list_stmt->execute();
$beh_list_res = $beh_list_stmt->get_result();
$recent_behaviors = [];
while ($b = $beh_list_res->fetch_assoc()) {
    $recent_behaviors[] = [
        'title' => $b['reason'] ?: 'บันทึกคะแนนความประพฤติ',
        'date' => date('d M Y', strtotime($b['created_at'])),
        'recordedBy' => $b['teacher_name'] ?: 'ครูเวรประจำวัน',
        'pointsChange' => intval($b['score_change']),
    ];
}

// 6. ตารางเรียน (timetables)
$day_of_week = date('l'); // Monday, Tuesday, ...
$time_stmt = $conn->prepare("
    SELECT tt.*, s.subject_code, s.subject_name, s.credit, t.name as teacher_name 
    FROM timetables tt 
    JOIN subjects s ON tt.subject_id = s.subject_id 
    JOIN teachers t ON tt.teacher_id = t.teacher_id 
    WHERE tt.room = ? AND tt.day_of_week = ? 
    ORDER BY tt.start_time ASC
");
$time_stmt->bind_param("ss", $student['room'], $day_of_week);
$time_stmt->execute();
$time_res = $time_stmt->get_result();

// ถ้าวันนี้ไม่มีคาบ ให้ดึงวันแรกที่มีตารางเรียนมาแสดงแทน
if ($time_res->num_rows === 0) {
    $time_fallback = $conn->prepare("
        SELECT tt.*, s.subject_code, s.subject_name, s.credit, t.name as teacher_name 
        FROM timetables tt 
        JOIN subjects s ON tt.subject_id = s.subject_id 
        JOIN teachers t ON tt.teacher_id = t.teacher_id 
        WHERE tt.room = ? 
        ORDER BY tt.start_time ASC 
        LIMIT 4
    ");
    $time_fallback->bind_param("s", $student['room']);
    $time_fallback->execute();
    $time_res = $time_fallback->get_result();
}

$schedule_list = [];
$now_time = date('H:i:s');
while ($sc = $time_res->fetch_assoc()) {
    $start = $sc['start_time'];
    $end = $sc['end_time'];
    $status = 'normal';
    if ($now_time >= $start && $now_time <= $end) {
        $status = 'inProgress';
    } else if ($now_time < $start) {
        $status = 'upcoming';
    }

    $schedule_list[] = [
        'timeRange' => substr($start, 0, 5) . ' - ' . substr($end, 0, 5) . ' น.',
        'room' => 'ห้อง ' . $sc['room'],
        'subjectName' => $sc['subject_name'],
        'teacherName' => $sc['teacher_name'],
        'status' => $status,
        'recentScore' => '18 /20',
    ];
}

// รวมข้อมูลส่งออก
$response = [
    'success' => true,
    'data' => [
        'student' => [
            'id' => $student['student_id'],
            'fullName' => $student['name'],
            'classroom' => $student['room'],
            'seatNumber' => intval($student['class_no'] ?: 1),
            'schoolName' => 'โรงเรียนพัฒนาวิทยาการ',
            'gpax' => $gpax,
            'status' => 'สถานะปกติ',
            'avatarUrl' => 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=200&auto=format&fit=crop&q=80',
            'birthDate' => '14 ก.พ. 2554',
            'age' => 13,
            'bloodGroup' => 'กรุ๊ป ' . ($student['blood_group'] ?: 'O'),
            'advisorName' => $teacher ? $teacher['name'] : 'ครูสมชาย ใจดี',
            'advisorPhone' => $teacher ? $teacher['phone_number'] : '081-111-1111',
            'guardianName' => $student['parent_name'] ?: 'นายมานะ ใจเย็น',
            'guardianRelation' => 'บิดา (ผู้ปกครองหลัก)',
            'guardianPhone' => $student['parent_phone_number'] ?: '089-500-0001',
        ],
        'attendance' => [
            'percentage' => $att_percentage,
            'statusText' => $att_percentage >= 80 ? 'สถานะปกติ เข้าเรียนสม่ำเสมอ' : 'มีสถิติการมาเรียนต่ำกว่าเกณฑ์',
            'note' => 'ผ่านเกณฑ์ขั้นต่ำของโรงเรียน (เกณฑ์ผ่าน ≥ 80% มีสิทธิ์สอบปลายภาค)',
            'presentCount' => $present,
            'lateCount' => $late,
            'businessLeaveCount' => $leave,
            'sickLeaveCount' => 0,
            'absentCount' => $absent,
        ],
        'conduct' => [
            'currentScore' => $current_conduct_score,
            'maxScore' => 100,
            'gradeLevel' => $current_conduct_score >= 90 ? 'ดีเยี่ยม (ระดับ A)' : ($current_conduct_score >= 80 ? 'ดี (ระดับ B)' : 'ผ่านเกณฑ์'),
            'recentRecords' => $recent_behaviors,
        ],
        'schedule' => $schedule_list,
    ]
];

echo json_encode($response, JSON_UNESCAPED_UNICODE);
?>
