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
        // --- บันทึกเช็คชื่อจากสแกน QR (scan_in หรือ scan_out) ---
        $input = json_decode(file_get_contents('php://input'), true);

        $student_id = trim($input['student_id'] ?? '');
        $teacher_id = trim($input['teacher_id'] ?? '');
        $date = trim($input['date'] ?? date('Y-m-d'));
        $scan_type = trim($input['scan_type'] ?? 'in'); // 'in' หรือ 'out'
        $status = trim($input['status'] ?? 'มาเรียน');

        if (empty($student_id) || empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจว่า student_id มีจริง
        $stmt = $conn->prepare("SELECT student_id, name FROM students WHERE student_id = ?");
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $res = $stmt->get_result();
        if ($res->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบรหัสนักเรียนนี้ในระบบ'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        $student = $res->fetch_assoc();

        $now_time = date('H:i:s');
        $attendance_id = 'ATT' . date('YmdHis') . rand(100, 999);

        // Ensure tables exist
        $conn->query("CREATE TABLE IF NOT EXISTS behaviors (behavior_id VARCHAR(50) PRIMARY KEY, student_id VARCHAR(50), teacher_id VARCHAR(50), score_change DECIMAL(5,2), reason TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");
        $conn->query("CREATE TABLE IF NOT EXISTS notifications (notification_id VARCHAR(50) PRIMARY KEY, student_id VARCHAR(50), title VARCHAR(255), message TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");

        $deduction_note = '';

        if ($scan_type === 'in') {
            // --- โลจิกคำนวณการมาสายเกิน 8 โมง หักนาทีละ 0.1 คะแนน ---
            $target_time = '08:00:00';
            if (strtotime($now_time) > strtotime($target_time)) {
                $status = 'สาย';
                $late_seconds = strtotime($now_time) - strtotime($target_time);
                $late_minutes = (int)ceil($late_seconds / 60);
                $deduct_score = round($late_minutes * 0.1, 2);

                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999);
                $reason = "มาสาย $late_minutes นาที (เข้าโรงเรียนเวลา $now_time)";
                $neg_score = -$deduct_score;

                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();

                $notif_id = 'NOTI' . date('YmdHis') . rand(100, 999);
                $notif_title = "ถูกหักคะแนนความประพฤติ (มาสาย)";
                $notif_msg = "เข้าโรงเรียนสาย $late_minutes นาที ถูกหัก $deduct_score คะแนน";
                $stmt_n = $conn->prepare("INSERT INTO notifications (notification_id, student_id, title, message) VALUES (?, ?, ?, ?)");
                $stmt_n->bind_param("ssss", $notif_id, $student_id, $notif_title, $notif_msg);
                $stmt_n->execute();

                $deduction_note = " (มาสาย $late_minutes นาที หัก $deduct_score คะแนน)";
            }

            // ถ้าสถานะระบุว่าขาด
            if ($status === 'ขาด') {
                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999);
                $reason = "ขาดเรียนโดยไม่แจ้งลา";
                $neg_score = -3.00;

                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();

                $notif_id = 'NOTI' . date('YmdHis') . rand(100, 999);
                $notif_title = "ถูกหักคะแนนความประพฤติ (ขาดเรียน)";
                $notif_msg = "ขาดเรียนโดยไม่แจ้งลา ถูกหัก 3.0 คะแนน";
                $stmt_n = $conn->prepare("INSERT INTO notifications (notification_id, student_id, title, message) VALUES (?, ?, ?, ?)");
                $stmt_n->bind_param("ssss", $notif_id, $student_id, $notif_title, $notif_msg);
                $stmt_n->execute();

                $deduction_note = " (ขาดเรียน หัก 3.0 คะแนน)";
            }

            // ใช้ ON DUPLICATE KEY UPDATE ป้องกันสแกนซ้ำ (unique key: student_id + date)
            $stmt = $conn->prepare("
                INSERT INTO daily_attendance (attendance_id, student_id, scanned_by_teacher_id, date, scan_in_time, daily_status)
                VALUES (?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE scan_in_time = VALUES(scan_in_time), daily_status = VALUES(daily_status)
            ");
            $stmt->bind_param("ssssss", $attendance_id, $student_id, $teacher_id, $date, $now_time, $status);
        } else {
            // --- scan_out: ตรวจสอบว่าเคยสแกนเข้าหรือไม่ ถ้าไม่มีสแกนเข้า หัก 3 คะแนน ---
            $chk = $conn->prepare("SELECT scan_in_time FROM daily_attendance WHERE student_id = ? AND date = ?");
            $chk->bind_param("ss", $student_id, $date);
            $chk->execute();
            $chk_res = $chk->get_result();

            if ($chk_res->num_rows === 0 || empty($chk_res->fetch_assoc()['scan_in_time'])) {
                // ไม่สแกนเข้า หัก 3 คะแนน
                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999);
                $reason = "ไม่สแกนเข้าโรงเรียน (สแกนเฉพาะออก)";
                $neg_score = -3.00;

                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();

                $notif_id = 'NOTI' . date('YmdHis') . rand(100, 999);
                $notif_title = "ถูกหักคะแนนความประพฤติ (ไม่สแกนเข้า/ออก)";
                $notif_msg = "ไม่สแกนเข้าโรงเรียน ถูกหัก 3.0 คะแนน";
                $stmt_n = $conn->prepare("INSERT INTO notifications (notification_id, student_id, title, message) VALUES (?, ?, ?, ?)");
                $stmt_n->bind_param("ssss", $notif_id, $student_id, $notif_title, $notif_msg);
                $stmt_n->execute();

                $deduction_note = " (ไม่สแกนเข้า หัก 3.0 คะแนน)";
            }

            // update เฉพาะ record ที่มีอยู่แล้ว หรือ insert ออก
            $stmt = $conn->prepare("
                INSERT INTO daily_attendance (attendance_id, student_id, scanned_by_teacher_id, date, scan_out_time, daily_status)
                VALUES (?, ?, ?, ?, ?, 'มาเรียน')
                ON DUPLICATE KEY UPDATE scan_out_time = VALUES(scan_out_time)
            ");
            $stmt->bind_param("sssss", $attendance_id, $student_id, $teacher_id, $date, $now_time);
        }

        $stmt->execute();

        echo json_encode([
            'success' => true,
            'message' => 'บันทึกสำเร็จ' . $deduction_note,
            'student_name' => $student['name'],
            'scan_type' => $scan_type,
            'time' => $now_time,
            'status' => $status
        ], JSON_UNESCAPED_UNICODE);

    } elseif ($method === 'GET') {
        // --- ดึงรายชื่อนักเรียนตามห้อง พร้อมสถานะเช็คชื่อวันนี้ (daily_attendance) ---
        $room = isset($_GET['room']) ? trim($_GET['room']) : '';
        $date = isset($_GET['date']) ? trim($_GET['date']) : date('Y-m-d');

        if (empty($room)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุห้อง'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("
            SELECT st.student_id, st.name, st.class_no,
                   da.daily_status, da.scan_in_time, da.scan_out_time
            FROM students st
            LEFT JOIN daily_attendance da ON st.student_id = da.student_id AND da.date = ?
            WHERE st.room = ?
            ORDER BY st.class_no ASC
        ");
        $stmt->bind_param("ss", $date, $room);
        $stmt->execute();
        $res = $stmt->get_result();

        $students = [];
        while ($row = $res->fetch_assoc()) {
            $students[] = $row;
        }

        echo json_encode(['success' => true, 'students' => $students], JSON_UNESCAPED_UNICODE);

    } else {
        echo json_encode(['success' => false, 'message' => 'Method ไม่รองรับ'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}