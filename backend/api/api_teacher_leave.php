<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$VALID_LEAVE_TYPES = ['ลาป่วย', 'ลากิจ'];

try {
    $method = $_SERVER['REQUEST_METHOD'];

    // ตรวจสอบว่าครูคนนี้เป็นที่ปรึกษาห้องอะไร (ใช้ซ้ำในทุก method)
    function get_advisor_room($conn, $teacher_id) {
        $stmt = $conn->prepare("SELECT advisor_room FROM teachers WHERE teacher_id = ?");
        $stmt->bind_param("s", $teacher_id);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        return $row ? $row['advisor_room'] : null;
    }

    // ==========================================================
    // POST: บันทึกการลาใหม่ (หรือแก้ไขถ้าลงวันเดิมซ้ำ)
    // ==========================================================
    if ($method === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);

        $student_id  = trim($input['student_id'] ?? '');
        $teacher_id  = trim($input['teacher_id'] ?? '');
        $leave_type  = trim($input['leave_type'] ?? '');
        $leave_date  = trim($input['leave_date'] ?? date('Y-m-d'));
        $reason      = trim($input['reason'] ?? '');

        if (empty($student_id) || empty($teacher_id) || empty($leave_type)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน (ต้องมี student_id, teacher_id, leave_type)'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        if (!in_array($leave_type, $VALID_LEAVE_TYPES, true)) {
            echo json_encode(['success' => false, 'message' => 'ประเภทการลาไม่ถูกต้อง (ต้องเป็น ลาป่วย หรือ ลากิจ)'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจสิทธิ์: ต้องเป็นครูที่ปรึกษาของห้องนักเรียนคนนี้เท่านั้น
        $advisor_room = get_advisor_room($conn, $teacher_id);
        if (empty($advisor_room)) {
            echo json_encode(['success' => false, 'message' => 'ครูคนนี้ไม่ได้เป็นครูที่ปรึกษา ไม่มีสิทธิ์บันทึกการลา'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("SELECT room FROM students WHERE student_id = ?");
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $student = $stmt->get_result()->fetch_assoc();

        if (!$student) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบนักเรียนคนนี้'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        if ($student['room'] !== $advisor_room) {
            echo json_encode(['success' => false, 'message' => 'ไม่มีสิทธิ์บันทึกการลาให้นักเรียนห้องอื่น'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $conn->begin_transaction();

        // บันทึกลง leave_requests (ถ้าวันเดิมมีอยู่แล้ว ให้อัปเดตทับ เพราะ 1 คน ลาได้ 1 ครั้งต่อวัน)
        $leave_id = 'LV' . date('YmdHis') . rand(1000, 9999);
        $stmt = $conn->prepare("
            INSERT INTO leave_requests (leave_id, student_id, recorded_by_teacher_id, leave_type, leave_date, reason)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                leave_type = VALUES(leave_type),
                reason = VALUES(reason),
                recorded_by_teacher_id = VALUES(recorded_by_teacher_id)
        ");
        $stmt->bind_param("ssssss", $leave_id, $student_id, $teacher_id, $leave_type, $leave_date, $reason);
        $stmt->execute();

        // Sync ไปที่ daily_attendance ของวันนั้น ให้สถานะตรงกับประเภทการลา
        $attendance_id = 'ATT' . date('YmdHis') . rand(1000, 9999);
        $stmt2 = $conn->prepare("
            INSERT INTO daily_attendance (attendance_id, student_id, scanned_by_teacher_id, date, daily_status)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                daily_status = VALUES(daily_status),
                scanned_by_teacher_id = VALUES(scanned_by_teacher_id)
        ");
        $stmt2->bind_param("sssss", $attendance_id, $student_id, $teacher_id, $leave_date, $leave_type);
        $stmt2->execute();

        $conn->commit();

        echo json_encode(['success' => true, 'message' => 'บันทึกการลาสำเร็จ', 'leave_id' => $leave_id], JSON_UNESCAPED_UNICODE);

    // ==========================================================
    // GET: ดูรายการลาของห้องที่ปรึกษา (หรือของนักเรียนคนใดคนหนึ่ง)
    // ==========================================================
    } elseif ($method === 'GET') {
        $teacher_id = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';
        $student_id = isset($_GET['student_id']) ? trim($_GET['student_id']) : '';

        if (empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ teacher_id'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $advisor_room = get_advisor_room($conn, $teacher_id);
        if (empty($advisor_room)) {
            echo json_encode(['success' => false, 'message' => 'ครูคนนี้ไม่ได้เป็นครูที่ปรึกษา'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        if (!empty($student_id)) {
            // ดูประวัติการลาของนักเรียนคนเดียว (ต้องอยู่ห้องที่ปรึกษาของครูคนนี้)
            $stmt = $conn->prepare("
                SELECT lr.leave_id, lr.student_id, s.name AS student_name, lr.leave_type, lr.leave_date, lr.reason, lr.created_at
                FROM leave_requests lr
                JOIN students s ON lr.student_id = s.student_id
                WHERE lr.student_id = ? AND s.room = ?
                ORDER BY lr.leave_date DESC
            ");
            $stmt->bind_param("ss", $student_id, $advisor_room);
        } else {
            // ดูรายการลาทั้งห้องที่ปรึกษา
            $stmt = $conn->prepare("
                SELECT lr.leave_id, lr.student_id, s.name AS student_name, lr.leave_type, lr.leave_date, lr.reason, lr.created_at
                FROM leave_requests lr
                JOIN students s ON lr.student_id = s.student_id
                WHERE s.room = ?
                ORDER BY lr.leave_date DESC
            ");
            $stmt->bind_param("s", $advisor_room);
        }

        $stmt->execute();
        $res = $stmt->get_result();
        $records = [];
        while ($row = $res->fetch_assoc()) {
            $records[] = [
                'leaveId'     => $row['leave_id'],
                'studentId'   => $row['student_id'],
                'studentName' => $row['student_name'],
                'leaveType'   => $row['leave_type'],
                'leaveDate'   => $row['leave_date'],
                'reason'      => $row['reason'],
                'createdAt'   => $row['created_at'],
            ];
        }

        echo json_encode(['success' => true, 'records' => $records], JSON_UNESCAPED_UNICODE);

    // ==========================================================
    // DELETE: ยกเลิกการลาที่บันทึกผิด
    // ==========================================================
    } elseif ($method === 'DELETE') {
        $input = json_decode(file_get_contents('php://input'), true);
        $leave_id   = trim($input['leave_id'] ?? '');
        $teacher_id = trim($input['teacher_id'] ?? '');

        if (empty($leave_id) || empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ leave_id และ teacher_id'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $advisor_room = get_advisor_room($conn, $teacher_id);
        if (empty($advisor_room)) {
            echo json_encode(['success' => false, 'message' => 'ครูคนนี้ไม่ได้เป็นครูที่ปรึกษา'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจสิทธิ์: ลบได้เฉพาะรายการของห้องที่ตัวเองดูแล
        $stmt = $conn->prepare("
            SELECT lr.student_id, lr.leave_date FROM leave_requests lr
            JOIN students s ON lr.student_id = s.student_id
            WHERE lr.leave_id = ? AND s.room = ?
        ");
        $stmt->bind_param("ss", $leave_id, $advisor_room);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();

        if (!$row) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบรายการลานี้ หรือไม่มีสิทธิ์ลบ'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $conn->begin_transaction();

        $stmt = $conn->prepare("DELETE FROM leave_requests WHERE leave_id = ?");
        $stmt->bind_param("s", $leave_id);
        $stmt->execute();

        // รีเซ็ตสถานะ daily_attendance ของวันนั้นกลับเป็น 'ขาด' เพราะไม่ถือว่าลาแล้ว
        // (ครูต้องมาเช็คชื่อใหม่ให้ถูกต้อง หากจริงๆ นักเรียนมาเรียน)
        $stmt2 = $conn->prepare("
            UPDATE daily_attendance SET daily_status = 'ขาด'
            WHERE student_id = ? AND date = ? AND daily_status IN ('ลาป่วย', 'ลากิจ')
        ");
        $stmt2->bind_param("ss", $row['student_id'], $row['leave_date']);
        $stmt2->execute();

        $conn->commit();

        echo json_encode(['success' => true, 'message' => 'ยกเลิกรายการลาสำเร็จ'], JSON_UNESCAPED_UNICODE);

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