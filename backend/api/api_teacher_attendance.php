<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

date_default_timezone_set('Asia/Bangkok');

include 'db.php';

function has_behavior_for_day(mysqli $conn, string $student_id, string $date, string $reason_prefix): bool
{
    $stmt = $conn->prepare(
        "SELECT 1 FROM behaviors
         WHERE student_id = ? AND DATE(created_at) = ? AND reason LIKE CONCAT(?, '%')
         LIMIT 1"
    );
    $stmt->bind_param('sss', $student_id, $date, $reason_prefix);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

try {
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'POST') {
        // --- บันทึกเช็คชื่อจากสแกน QR หรือกรอกรหัส (scan_in หรือ scan_out) ---
        $input = json_decode(file_get_contents('php://input'), true);

        $student_id = trim($input['student_id'] ?? '');
        $teacher_id = trim($input['teacher_id'] ?? '');
        // ใช้วันจาก Server เท่านั้น ป้องกันการส่งวันที่ย้อนหลังจาก Client
        $date = date('Y-m-d');
        $scan_type = trim($input['scan_type'] ?? 'in'); // 'in' หรือ 'out'
        $status = trim($input['status'] ?? 'มาเรียน');

        // รับค่าเวลาจาก client ถ้ามี (เช่น '08:10:00' หรือ '08:10') หากไม่มีให้ใช้เวลาปัจจุบันของเซิร์ฟเวอร์
        // ใช้เวลาจาก Server เท่านั้น ป้องกันการส่งเวลาเช้าปลอมจาก Client
        $now_time = date('H:i:s');

        if (empty($student_id) || empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจว่า student_id มีจริง
        // ตรวจสิทธิ์จากฐานข้อมูลจริง ไม่เชื่อ teacher_id จาก Client เพียงอย่างเดียว
        $teacher_stmt = $conn->prepare(
            "SELECT is_disciplinary, advisor_room FROM teachers WHERE teacher_id = ? LIMIT 1"
        );
        $teacher_stmt->bind_param("s", $teacher_id);
        $teacher_stmt->execute();
        $teacher = $teacher_stmt->get_result()->fetch_assoc();

        if (!$teacher) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'ไม่พบข้อมูลครูผู้ทำรายการ'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $can_scan = (int)$teacher['is_disciplinary'] === 1 || !empty($teacher['advisor_room']);
        if (!$can_scan) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'ครูผู้สอนไม่มีสิทธิ์สแกน QR นักเรียน'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("SELECT student_id, name FROM students WHERE student_id = ?");
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $res = $stmt->get_result();
        if ($res->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบรหัสนักเรียนนี้ในระบบ'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        $student = $res->fetch_assoc();

        $attendance_id = 'ATT' . date('YmdHis') . rand(100, 999);

        // Ensure tables exist & columns support decimal scores
        @$conn->query("CREATE TABLE IF NOT EXISTS behaviors (behavior_id VARCHAR(50) PRIMARY KEY, student_id VARCHAR(50), teacher_id VARCHAR(50), score_change DECIMAL(6,2), reason TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");
        @$conn->query("ALTER TABLE behaviors MODIFY score_change DECIMAL(6,2) NOT NULL");
        @$conn->query("ALTER TABLE daily_attendance MODIFY daily_status VARCHAR(50) DEFAULT 'มาเรียน'");

        $deduction_note = '';

        if ($scan_type === 'in') {
            // --- โลจิกคำนวณการมาสายเกิน 8 โมง หักนาทีละ 0.1 คะแนน ---
            $target_time = '08:00:00';
            $now_stamp = strtotime("1970-01-01 $now_time");
            $target_stamp = strtotime("1970-01-01 $target_time");

            if ($now_stamp > $target_stamp) {
                $status = 'มาสาย';
                $late_seconds = $now_stamp - $target_stamp;
                $late_minutes = (int)ceil($late_seconds / 60);
                $deduct_score = round($late_minutes * 0.1, 2);

                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999);
                $reason = "มาสาย $late_minutes นาที (เข้าโรงเรียนเวลา $now_time)";
                $neg_score = -$deduct_score;

                if (!has_behavior_for_day($conn, $student_id, $date, 'มาสาย')) {
                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();
                }

                $deduction_note = " (มาสาย $late_minutes นาที หัก $deduct_score คะแนน)";
            }

            // ถ้าสถานะระบุว่าขาด
            if ($status === 'ขาด') {
                $beh_id = 'BEH' . date('YmdHis') . rand(100, 999);
                $reason = "ขาดเรียนโดยไม่แจ้งลา";
                $neg_score = -3.00;

                if (!has_behavior_for_day($conn, $student_id, $date, 'ขาดเรียนโดยไม่แจ้งลา')) {
                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();
                }

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

                if (!has_behavior_for_day($conn, $student_id, $date, 'ไม่สแกนเข้าโรงเรียน')) {
                $stmt_b = $conn->prepare("INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason) VALUES (?, ?, ?, ?, ?)");
                $stmt_b->bind_param("sssds", $beh_id, $student_id, $teacher_id, $neg_score, $reason);
                $stmt_b->execute();
                }

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
