<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$VALID_STATUSES = ['มาเรียน', 'มาสาย', 'ขาด', 'ลาป่วย', 'ลากิจ'];

try {
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);

        $schedule_id = trim($input['schedule_id'] ?? '');
        $date        = trim($input['date'] ?? date('Y-m-d'));
        $teacher_id  = trim($input['teacher_id'] ?? '');   // <-- ต้องส่งมาจากฝั่งครูที่ล็อกอินอยู่
        $records     = $input['records'] ?? [];

        if (empty($schedule_id) || empty($teacher_id) || empty($records) || !is_array($records)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน (ต้องมี schedule_id, teacher_id, records)'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจว่า schedule_id มีจริง และเป็นคาบของครูคนนี้จริง (กันครูคนอื่นมาแก้ข้อมูลคาบที่ไม่ใช่ของตัวเอง)
        $stmt = $conn->prepare("SELECT teacher_id, room FROM timetables WHERE schedule_id = ?");
        $stmt->bind_param("s", $schedule_id);
        $stmt->execute();
        $sched = $stmt->get_result()->fetch_assoc();

        if (!$sched) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        if ($sched['teacher_id'] !== $teacher_id) {
            echo json_encode(['success' => false, 'message' => 'ไม่มีสิทธิ์บันทึกคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $conn->begin_transaction();
        $saved_count = 0;

        $stmt_att = $conn->prepare("
            INSERT INTO subject_attendance (subject_att_id, schedule_id, student_id, date, status)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE status = VALUES(status)
        ");

        foreach ($records as $rec) {
            $student_id = trim($rec['student_id'] ?? '');
            $status     = trim($rec['status'] ?? 'มาเรียน');

            if (empty($student_id)) continue;

            // นักเรียนต้องอยู่ห้องเดียวกับคาบที่กำลังเช็คชื่อ
            $student_stmt = $conn->prepare("SELECT room FROM students WHERE student_id = ? LIMIT 1");
            $student_stmt->bind_param("s", $student_id);
            $student_stmt->execute();
            $student_row = $student_stmt->get_result()->fetch_assoc();
            if (!$student_row || $student_row['room'] !== $sched['room']) {
                throw new Exception("นักเรียน $student_id ไม่ได้อยู่ห้อง {$sched['room']} ของคาบนี้");
            }

            if (!in_array($status, $VALID_STATUSES, true)) {
                throw new Exception("สถานะไม่ถูกต้อง: $status (student_id: $student_id)");
            }

            $subject_att_id = 'SATT' . date('YmdHis') . rand(1000, 9999);
            $stmt_att->bind_param("sssss", $subject_att_id, $schedule_id, $student_id, $date, $status);
            $stmt_att->execute();
            $saved_count++;

        }

        $conn->commit();

        echo json_encode([
            'success' => true,
            'message' => "บันทึกสำเร็จ $saved_count รายการ"
        ], JSON_UNESCAPED_UNICODE);

    } elseif ($method === 'GET') {
        $schedule_id = isset($_GET['schedule_id']) ? trim($_GET['schedule_id']) : '';
        $date        = isset($_GET['date']) ? trim($_GET['date']) : date('Y-m-d');
        $teacher_id  = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';

        if (empty($schedule_id) || empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ schedule_id และ teacher_id'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("SELECT room, teacher_id FROM timetables WHERE schedule_id = ?");
        $stmt->bind_param("s", $schedule_id);
        $stmt->execute();
        $sched = $stmt->get_result()->fetch_assoc();

        if (!$sched) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        if ($sched['teacher_id'] !== $teacher_id) {
            echo json_encode(['success' => false, 'message' => 'ไม่มีสิทธิ์ดูคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        $room = $sched['room'];

        $stmt = $conn->prepare("
            SELECT st.student_id, st.name, st.class_no, sa.status
            FROM students st
            LEFT JOIN subject_attendance sa
                ON st.student_id = sa.student_id AND sa.schedule_id = ? AND sa.date = ?
            WHERE st.room = ?
            ORDER BY st.class_no ASC
        ");
        $stmt->bind_param("sss", $schedule_id, $date, $room);
        $stmt->execute();
        $res = $stmt->get_result();

        $students = [];
        while ($row = $res->fetch_assoc()) {
            $students[] = $row;
        }

        echo json_encode(['success' => true, 'room' => $room, 'students' => $students], JSON_UNESCAPED_UNICODE);

    } else {
        echo json_encode(['success' => false, 'message' => 'Method ไม่รองรับ'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    if (isset($conn) && $conn->connect_errno === 0) {
        $conn->rollback();
    }
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}
