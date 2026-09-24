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

try {
    // 1. ดึงข้อมูลนักเรียน
    $stmt = $conn->prepare("SELECT * FROM students WHERE student_id = ?");
    if (!$stmt) {
        throw new Exception("ไม่สามารถเตรียมคำสั่ง SQL นักเรียนได้: " . $conn->error);
    }
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

    // 2. ดึงข้อมูลครูที่ปรึกษา (แบบ Safe fallback)
    $teacher = null;
    try {
        $stmt_t = $conn->prepare("
            SELECT t.* FROM teachers t
            JOIN students s ON (s.advisor_teacher_id = t.teacher_id)
            WHERE s.student_id = ?
        ");
        if ($stmt_t) {
            $stmt_t->bind_param("s", $student_id);
            $stmt_t->execute();
            $teacher_res = $stmt_t->get_result();
            if ($teacher_res && $teacher_res->num_rows > 0) {
                $teacher = $teacher_res->fetch_assoc();
            }
        }
    } catch (Throwable $te) {
        // ข้ามข้อผิดพลาดครูที่ปรึกษาไปใช้ fallback
    }

    // 3. คำนวณ GPAX จากตาราง grades + subjects
    $gpax = 3.78;
    try {
        $grade_stmt = $conn->prepare("
            SELECT g.grade_result, s.credit 
            FROM grades g 
            JOIN subjects s ON g.subject_id = s.subject_id 
            WHERE g.student_id = ?
        ");
        if ($grade_stmt) {
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
            if ($total_credits > 0) {
                $gpax = round($total_points / $total_credits, 2);
            }
        }
    } catch (Throwable $ge) {}

    // 4. สถิติการมาเรียน (daily_attendance)
    $present = 0;
    $late = 0;
    $leave = 0;
    $absent = 0;
    try {
        $att_stmt = $conn->prepare("
            SELECT daily_status, COUNT(*) as count 
            FROM daily_attendance 
            WHERE student_id = ? 
            GROUP BY daily_status
        ");
        if ($att_stmt) {
            $att_stmt->bind_param("s", $student_id);
            $att_stmt->execute();
            $att_res = $att_stmt->get_result();

            while ($r = $att_res->fetch_assoc()) {
                if ($r['daily_status'] === 'มาเรียน') $present = intval($r['count']);
                else if ($r['daily_status'] === 'มาสาย') $late = intval($r['count']);
                else if ($r['daily_status'] === 'ลา') $leave = intval($r['count']);
                else if ($r['daily_status'] === 'ขาด') $absent = intval($r['count']);
            }
        }
    } catch (Throwable $ae) {}

    $total_days = $present + $late + $leave + $absent;
    $att_percentage = $total_days > 0 ? round((($present + $late) / $total_days) * 100, 1) : 0;

    // 5. คะแนนความประพฤติ (behaviors)
    $current_conduct_score = 100.0;
    $recent_behaviors = [];
    try {
        $beh_sum_stmt = $conn->prepare("SELECT SUM(score_change) as total_change FROM behaviors WHERE student_id = ?");
        if ($beh_sum_stmt) {
            $beh_sum_stmt->bind_param("s", $student_id);
            $beh_sum_stmt->execute();
            $beh_sum_res = $beh_sum_stmt->get_result()->fetch_assoc();
            $score_change = $beh_sum_res['total_change'] !== null ? floatval($beh_sum_res['total_change']) : 0.0;
            $current_conduct_score = round(max(0, min(100, 100 + $score_change)), 2);
        }

        // รายการความประพฤติล่าสุด
        $beh_list_stmt = $conn->prepare("
            SELECT b.score_change, b.reason, b.created_at, t.name as teacher_name 
            FROM behaviors b 
            LEFT JOIN teachers t ON b.teacher_id = t.teacher_id 
            WHERE b.student_id = ? 
            ORDER BY b.created_at DESC 
            LIMIT 5
        ");
        if ($beh_list_stmt) {
            $beh_list_stmt->bind_param("s", $student_id);
            $beh_list_stmt->execute();
            $beh_list_res = $beh_list_stmt->get_result();
            while ($b = $beh_list_res->fetch_assoc()) {
                $recent_behaviors[] = [
                    'title' => $b['reason'] ?: 'บันทึกคะแนนความประพฤติ',
                    'date' => date('d M Y', strtotime($b['created_at'])),
                    'recordedBy' => $b['teacher_name'] ?: 'ครูเวรประจำวัน',
                    'pointsChange' => round(floatval($b['score_change']), 2),
                ];
            }
        }
    } catch (Throwable $be) {}

    // 6. ตารางเรียน (timetables)
    $schedule_list = [];
    try {
        $day_of_week = date('l'); // Monday, Tuesday, ...
        $student_room = isset($student['room']) ? $student['room'] : 'ม.4/1';

        $time_stmt = $conn->prepare("
            SELECT tt.*, s.subject_code, s.subject_name, s.credit, t.name as teacher_name 
            FROM timetables tt 
            JOIN subjects s ON tt.subject_id = s.subject_id 
            JOIN teachers t ON tt.teacher_id = t.teacher_id 
            WHERE tt.room = ? AND tt.day_of_week = ? 
            ORDER BY tt.start_time ASC
        ");
        if ($time_stmt) {
            $time_stmt->bind_param("ss", $student_room, $day_of_week);
            $time_stmt->execute();
            $time_res = $time_stmt->get_result();

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
                if ($time_fallback) {
                    $time_fallback->bind_param("s", $student_room);
                    $time_fallback->execute();
                    $time_res = $time_fallback->get_result();
                }
            }

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
        }
    } catch (Throwable $se) {}

    // รวมข้อมูลส่งออก
    $response = [
        'success' => true,
        'data' => [
            'student' => [
                'id' => $student['student_id'],
                'fullName' => $student['name'],
                'classroom' => isset($student['room']) ? $student['room'] : 'ม.4/1',
                'seatNumber' => intval(isset($student['class_no']) ? $student['class_no'] : 1),
                'schoolName' => 'โรงเรียนพัฒนาวิทยาการ',
                'gpax' => $gpax,
                'status' => 'สถานะปกติ',
                'avatarUrl' => 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=200&auto=format&fit=crop&q=80',
                'birthDate' => '14 ก.พ. 2554',
                'age' => 13,
                'bloodGroup' => 'กรุ๊ป ' . (isset($student['blood_group']) ? $student['blood_group'] : 'O'),
                'advisorName' => $teacher ? $teacher['name'] : 'ครูสมชาย ใจดี',
                'advisorPhone' => $teacher ? $teacher['phone_number'] : '081-111-1111',
                'guardianName' => isset($student['parent_name']) ? $student['parent_name'] : 'นายมานะ ใจเย็น',
                'guardianRelation' => 'บิดา (ผู้ปกครองหลัก)',
                'guardianPhone' => isset($student['parent_phone_number']) ? $student['parent_phone_number'] : '089-500-0001',
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

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
