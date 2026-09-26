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
        // --- บันทึกคะแนนความประพฤติ (ลง behaviors table) ---
        $input = json_decode(file_get_contents('php://input'), true);

        $student_id = trim($input['student_id'] ?? '');
        $teacher_id = trim($input['teacher_id'] ?? '');
        $score_change = isset($input['score_change']) ? (float)$input['score_change'] : null;
        $reason = trim($input['reason'] ?? '');

        if (empty($student_id) || empty($teacher_id) || $score_change === null || empty($reason)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน (ต้องมี student_id, teacher_id, score_change, reason)'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // --- ตรวจสิทธิ์: เฉพาะครูที่ is_disciplinary = 1 เท่านั้นที่บันทึกได้ ---
        $stmt = $conn->prepare("SELECT is_disciplinary FROM teachers WHERE teacher_id = ?");
        $stmt->bind_param("s", $teacher_id);
        $stmt->execute();
        $res = $stmt->get_result();

        if ($res->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบข้อมูลครู'], JSON_UNESCAPED_UNICODE);
            exit();
        }
        $teacher = $res->fetch_assoc();

        if ((int)$teacher['is_disciplinary'] !== 1) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'ไม่มีสิทธิ์บันทึกคะแนนความประพฤติ'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // ตรวจว่า student_id มีจริง
        $stmt = $conn->prepare("SELECT student_id FROM students WHERE student_id = ?");
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'ไม่พบรหัสนักเรียนนี้ในระบบ'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        // Auto create tables if not exists
        $conn->query("CREATE TABLE IF NOT EXISTS behaviors (behavior_id VARCHAR(50) PRIMARY KEY, student_id VARCHAR(50), teacher_id VARCHAR(50), score_change DECIMAL(5,2), reason TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)");

        $behavior_id = 'BEH' . date('YmdHis') . rand(100, 999);

        $stmt = $conn->prepare("
            INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->bind_param("sssds", $behavior_id, $student_id, $teacher_id, $score_change, $reason);
        $stmt->execute();

        echo json_encode([
            'success' => true,
            'message' => 'บันทึกคะแนนความประพฤติสำเร็จ',
            'behavior_id' => $behavior_id
        ], JSON_UNESCAPED_UNICODE);

    } elseif ($method === 'GET') {
        // --- ดึงประวัติที่ครูคนนี้เคยบันทึก ---
        $teacher_id = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';

        if (empty($teacher_id)) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ teacher_id'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("
            SELECT b.behavior_id, b.student_id, st.name as student_name, b.score_change, b.reason, b.created_at
            FROM behaviors b
            JOIN students st ON b.student_id = st.student_id
            WHERE b.teacher_id = ?
            ORDER BY b.created_at DESC
        ");
        $stmt->bind_param("s", $teacher_id);
        $stmt->execute();
        $res = $stmt->get_result();

        $history = [];
        while ($row = $res->fetch_assoc()) {
            $history[] = $row;
        }

        echo json_encode(['success' => true, 'history' => $history], JSON_UNESCAPED_UNICODE);

    } else {
        echo json_encode(['success' => false, 'message' => 'Method ไม่รองรับ'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}