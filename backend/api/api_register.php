<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$input = json_decode(file_get_contents('php://input'), true);
$student_id = isset($input['student_id']) ? trim(strtoupper($input['student_id'])) : '';
$password   = isset($input['password'])   ? $input['password'] : '';

// Validate
if (empty($student_id) || empty($password)) {
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

// ตรวจสอบว่า student_id มีอยู่ในระบบ
$check = $conn->prepare("SELECT student_id FROM students WHERE student_id = ?");
$check->bind_param("s", $student_id);
$check->execute();
$res = $check->get_result();

if ($res->num_rows === 0) {
    echo json_encode([
        'success' => false,
        'message' => 'ไม่พบรหัสนักเรียน "' . $student_id . '" ในระบบ กรุณาติดต่อครูผู้ดูแล'
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

// อัปเดตรหัสผ่านของนักเรียน
$stmt = $conn->prepare("UPDATE students SET password = ? WHERE student_id = ?");
$stmt->bind_param("ss", $password, $student_id);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'ลงทะเบียนสำเร็จ สามารถเข้าสู่ระบบได้เลย'
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'
    ], JSON_UNESCAPED_UNICODE);
}
?>
