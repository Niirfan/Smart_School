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
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'POST') {
        // --- บันทึกเช็คชื่อรายคาบ (manual, เลือกทีละคนหรือทั้งห้อง) ---
        // รับเป็น array ของนักเรียนหลายคนพร้อมกัน เพื่อให้กดบันทึกทีเดียวทั้งห้อง
        $input = json_decode(file_get_contents('php://input'), true);

        $schedule_id = trim($input['schedule_id'] ?? '');
        $date = trim($input['date'] ?? date('Y-m-d'));
        $records = $input['records'] ?? []; // [{student_id, status}, ...]

        if (empty($schedule_id) || empty($records) || !is_array($records)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจว่า schedule_id มีจริง
        $stmt = $conn->prepare("SELECT schedule_id FROM timetables WHERE schedule_id = ?");
        $stmt->bind_param("s", $schedule_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $conn->begin_transaction();
        $saved_count = 0;

        $stmt = $conn->prepare("
            INSERT INTO subject_attendance (subject_att_id, schedule_id, student_id, date, status)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE status = VALUES(status)
        ");

        foreach ($records as $rec) {
            $student_id = trim($rec['student_id'] ?? '');
            $status = trim($rec['status'] ?? 'มาเรียน');

            if (empty($student_id)) continue;

            $subject_att_id = 'SATT' . date('YmdHis') . rand(100, 999) . $saved_count;
            $stmt->bind_param("sssss", $subject_att_id, $schedule_id, $student_id, $date, $status);
            $stmt->execute();
            $saved_count++;

            // หากขาดโดยไม่แจ้งลา หัก 3 คะแนน
            if ($status === 'ขาด') {
                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999) . $saved_count;
                $reason = "ขาดเรียนโดยไม่แจ้งลา (รายคาบ)";
                $neg_score = -3.00;

                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, 'SYSTEM', ?, ?)");
                $stmt_b->bind_param("ssds", $beh_id, $student_id, $neg_score, $reason);
                $stmt_b->execute();

                $notif_id = 'NOTI' . date('YmdHis') . rand(100, 999) . $saved_count;
                $notif_title = "ถูกหักคะแนนความประพฤติ (ขาดเรียน)";
                $notif_msg = "ขาดเรียนโดยไม่แจ้งลา (ถูกหัก 3.0 คะแนน)";
                $stmt_n = $conn->prepare("INSERT INTO notifications (notification_id, student_id, title, message) VALUES (?, ?, ?, ?)");
                $stmt_n->bind_param("ssss", $notif_id, $student_id, $notif_title, $notif_msg);
                $stmt_n->execute();
            }
        }

        $conn->commit();

        echo json_encode([
            'success' => true,
            'message' => "บันทึกสำเร็จ $saved_count รายการ"
        ], JSON_UNESCAPED_UNICODE);

    } elseif ($method === 'GET') {
        // --- ดึงรายชื่อนักเรียนตาม schedule_id พร้อมสถานะเช็คชื่อวันนี้ (subject_attendance) ---
        $schedule_id = isset($_GET['schedule_id']) ? trim($_GET['schedule_id']) : '';
        $date = isset($_GET['date']) ? trim($_GET['date']) : date('Y-m-d');

        if (empty($schedule_id)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ schedule_id'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // หา room จาก timetables ก่อน เพื่อดึงรายชื่อนักเรียนในห้องนั้น
        $stmt = $conn->prepare("SELECT room FROM timetables WHERE schedule_id = ?");
        $stmt->bind_param("s", $schedule_id);
        $stmt->execute();
        $res = $stmt->get_result();
        if ($res->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบคาบเรียนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        $room = $res->fetch_assoc()['room'];

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
    $conn->rollback();
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}