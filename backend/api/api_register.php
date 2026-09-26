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
    $input = json_decode(file_get_contents('php://input'), true);
    $account_type = strtolower(trim($input['account_type'] ?? 'student'));
    $account_id = isset($input['account_id'])
        ? trim(strtoupper($input['account_id']))
        : trim(strtoupper($input['student_id'] ?? ''));
    $password   = isset($input['password'])   ? $input['password'] : '';

    if (!in_array($account_type, ['student', 'teacher'], true) || empty($account_id) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'กรุณากรอกรหัสนักเรียนและรหัสผ่าน'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (strlen($password) < 6) {
        echo json_encode([
            'success' => false,
            'message' => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $table = $account_type === 'teacher' ? 'teachers' : 'students';
    $id_column = $account_type === 'teacher' ? 'teacher_id' : 'student_id';
    $check = $conn->prepare("SELECT $id_column, is_registered FROM $table WHERE $id_column = ?");
    if (!$check) {
        throw new Exception("คำสั่ง SQL ตรวจสอบนักเรียนผิดพลาด: " . $conn->error);
    }
    $check->bind_param("s", $account_id);
    $check->execute();
    $res = $check->get_result();

    if ($res->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'ไม่พบรหัสประจำตัว "' . $account_id . '" ในระบบ กรุณาติดต่อครูผู้ดูแล'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $account = $res->fetch_assoc();
    if ((int)($account['is_registered'] ?? 0) === 1) {
        echo json_encode([
            'success' => false,
            'message' => 'รหัสประจำตัวนี้ลงทะเบียนแล้ว หากลืมรหัสผ่านให้ติดต่อผู้ดูแลระบบ'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $hashed = password_hash($password, PASSWORD_BCRYPT);
    $stmt = $conn->prepare("UPDATE $table SET password = ?, is_registered = 1 WHERE $id_column = ?");
    if (!$stmt) {
        throw new Exception("คำสั่ง SQL อัปเดตรหัสผ่านผิดพลาด: " . $conn->error);
    }
    $stmt->bind_param("ss", $hashed, $account_id);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'ลงทะเบียนสำเร็จ สามารถเข้าสู่ระบบได้เลย'
        ], JSON_UNESCAPED_UNICODE);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'เกิดข้อผิดพลาดในการบันทึกรหัสผ่าน กรุณาลองใหม่อีกครั้ง'
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
