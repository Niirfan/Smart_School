<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

try {
    $teacher_id = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';

    if (empty($teacher_id)) {
        echo json_encode(['success' => false, 'message' => 'กรุณาระบุรหัสครู'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // --- 1. ข้อมูลครู (คงรูปแบบ snake_case เดิม ให้ตรงกับ TeacherModel.fromJson) ---
    $stmt = $conn->prepare("SELECT teacher_id, name, department, phone_number, address, blood_group, is_disciplinary, advisor_room FROM teachers WHERE teacher_id = ?");
    $stmt->bind_param("s", $teacher_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'ไม่พบข้อมูลครู'], JSON_UNESCAPED_UNICODE);
        exit();
    }
    $teacher = $res->fetch_assoc();
    $advisor_room = $teacher['advisor_room'];

    // --- 2. ตารางสอนวันนี้ — แปลงเป็น camelCase ให้ตรงกับ ScheduleItem.fromJson ---
    $today_en = date('l');
    $today_date = date('Y-m-d');
    $now_time = date('H:i:s');

    $stmt = $conn->prepare("
        SELECT t.schedule_id, t.subject_id, s.subject_name, s.subject_code, t.room,
               t.start_time, t.end_time, tc.name AS teacher_name
        FROM timetables t
        JOIN subjects s ON t.subject_id = s.subject_id
        JOIN teachers tc ON t.teacher_id = tc.teacher_id
        WHERE t.teacher_id = ? AND t.day_of_week = ?
        ORDER BY t.start_time ASC
    ");
    $stmt->bind_param("ss", $teacher_id, $today_en);
    $stmt->execute();
    $res = $stmt->get_result();

    $today_schedule = [];
    $rooms_today = [];
    while ($row = $res->fetch_assoc()) {
        $start = $row['start_time'];
        $end = $row['end_time'];

        $status = 'normal';
        if ($now_time >= $start && $now_time <= $end) {
            $status = 'inProgress';
        } elseif ($now_time < $start) {
            $status = 'upcoming';
        }

        $today_schedule[] = [
            'scheduleId'  => $row['schedule_id'],   // เพิ่มใหม่: จำเป็นสำหรับหน้าเช็คชื่อรายคาบ (api_teacher_subject_attendance.php)
            'timeRange'   => substr($start, 0, 5) . ' - ' . substr($end, 0, 5) . ' น.',
            'room'        => $row['room'],
            'subjectName' => $row['subject_name'],
            'teacherName' => $row['teacher_name'],
            'status'      => $status,
            'subjectCode' => $row['subject_code'],
        ];
        $rooms_today[] = $row['room'];
    }
    $rooms_today = array_unique($rooms_today);
    $periods_today = count($today_schedule);

    // --- 3. สถิตินักเรียนในคาบวันนี้ (คงพฤติกรรมเดิม เพื่อไม่ให้การ์ด stats เดิมพัง) ---
    $students_count = 0;
    $not_checked_in = 0;
    if (!empty($rooms_today)) {
        $placeholders = implode(',', array_fill(0, count($rooms_today), '?'));
        $types = str_repeat('s', count($rooms_today));

        $stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM students WHERE room IN ($placeholders)");
        $stmt->bind_param($types, ...$rooms_today);
        $stmt->execute();
        $students_count = (int)$stmt->get_result()->fetch_assoc()['cnt'];

        $types2 = str_repeat('s', count($rooms_today)) . 's';
        $params2 = array_merge($rooms_today, [$today_date]);
        $stmt = $conn->prepare("
            SELECT COUNT(*) as cnt FROM students st
            WHERE st.room IN ($placeholders)
            AND st.student_id NOT IN (SELECT student_id FROM daily_attendance WHERE date = ?)
        ");
        $stmt->bind_param($types2, ...$params2);
        $stmt->execute();
        $not_checked_in = (int)$stmt->get_result()->fetch_assoc()['cnt'];
    }

    // --- 4. สถิติห้องที่ปรึกษา + รายชื่อขาด/ลา (ฟิลด์ใหม่ เสริมเข้ามา ไม่กระทบของเดิม) ---
    $advisor_room_stats = null;
    $absent_or_leave_list = [];

    if (!empty($advisor_room)) {
        $stmt = $conn->prepare("SELECT student_id, name FROM students WHERE room = ? ORDER BY class_no ASC");
        $stmt->bind_param("s", $advisor_room);
        $stmt->execute();
        $res = $stmt->get_result();
        $advisor_students = [];
        while ($row = $res->fetch_assoc()) {
            $advisor_students[$row['student_id']] = $row['name'];
        }
        $total_students = count($advisor_students);

        $present = 0; $late = 0; $sick_leave = 0; $business_leave = 0; $absent = 0;
        $checked_in_ids = [];

        if ($total_students > 0) {
            $ids = array_keys($advisor_students);
            $placeholders = implode(',', array_fill(0, count($ids), '?'));
            $types = str_repeat('s', count($ids)) . 's';
            $params = array_merge($ids, [$today_date]);

            $stmt = $conn->prepare("
                SELECT student_id, daily_status FROM daily_attendance
                WHERE student_id IN ($placeholders) AND date = ?
            ");
            $stmt->bind_param($types, ...$params);
            $stmt->execute();
            $res = $stmt->get_result();

            while ($row = $res->fetch_assoc()) {
                $checked_in_ids[] = $row['student_id'];
                $name = $advisor_students[$row['student_id']];
                switch ($row['daily_status']) {
                    case 'มาเรียน': $present++; break;
                    case 'มาสาย':
                        $late++;
                        $absent_or_leave_list[] = ['studentId' => $row['student_id'], 'name' => $name, 'status' => 'มาสาย'];
                        break;
                    case 'ลาป่วย':
                        $sick_leave++;
                        $absent_or_leave_list[] = ['studentId' => $row['student_id'], 'name' => $name, 'status' => 'ลาป่วย'];
                        break;
                    case 'ลากิจ':
                        $business_leave++;
                        $absent_or_leave_list[] = ['studentId' => $row['student_id'], 'name' => $name, 'status' => 'ลากิจ'];
                        break;
                    case 'ขาด':
                        $absent++;
                        $absent_or_leave_list[] = ['studentId' => $row['student_id'], 'name' => $name, 'status' => 'ขาด'];
                        break;
                }
            }
        }

        // แสดงรายชื่อที่ยังไม่มีบันทึกด้วย เพื่อให้ครูเห็นเด็กที่ยังไม่เช็คชื่อ
        foreach ($advisor_students as $student_id => $student_name) {
            if (!in_array($student_id, $checked_in_ids, true)) {
                $absent_or_leave_list[] = [
                    'studentId' => $student_id,
                    'name' => $student_name,
                    'status' => 'ยังไม่เช็คชื่อ',
                ];
            }
        }

        $advisor_room_stats = [
            'room' => $advisor_room,
            'totalStudents' => $total_students,
            'presentCount' => $present,
            'lateCount' => $late,
            'sickLeaveCount' => $sick_leave,
            'businessLeaveCount' => $business_leave,
            'absentCount' => $absent,
            'notCheckedInCount' => $total_students - count($checked_in_ids),
        ];
    }

    // --- ผลลัพธ์: คงโครงสร้างเดิม (teacher, today_schedule, stats) + เพิ่มฟิลด์ใหม่ ---
    echo json_encode([
        'success' => true,
        'teacher' => $teacher,                    // snake_case เดิม — ตรงกับ TeacherModel.fromJson
        'today_schedule' => $today_schedule,       // camelCase ใหม่ — ตรงกับ ScheduleItem.fromJson (มี scheduleId แล้ว)
        'stats' => [                               // snake_case เดิม — ตรงกับ TeacherStats.fromJson
            'periods_today' => $periods_today,
            'students_count' => $students_count,
            'not_checked_in_today' => $not_checked_in,
        ],
        'advisor_room_stats' => $advisor_room_stats,   // ฟิลด์ใหม่ (Phase 3 ค่อยเพิ่ม model รองรับ)
        'absent_or_leave_list' => $absent_or_leave_list, // ฟิลด์ใหม่
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}
