<?php
/**
 * api_teacher_login.php
 * ระบบล็อกอินสำหรับครู - รองรับทั้ง BCrypt Hash และ Plain Text (ช่วงเปลี่ยนผ่าน)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

// รับ input
$input = json_decode(file_get_contents('php://input'), true);
$teacher_id = trim($input['teacher_id'] ?? '');
$password   = (string)($input['password'] ?? '');

if ($teacher_id === '' || $password === '') {
    echo json_encode(['success' => false, 'message' => 'กรุณากรอกรหัสครูและรหัสผ่าน'], JSON_UNESCAPED_UNICODE);
    exit;
}

// SYSTEM เป็นบัญชีสำหรับงานอัตโนมัติเท่านั้น ห้ามใช้เข้าสู่ระบบครู
if (strtoupper($teacher_id) === 'SYSTEM') {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'บัญชีระบบไม่สามารถเข้าสู่ระบบได้'], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $stmt = $conn->prepare("SELECT teacher_id, password, name, department, phone_number, address, blood_group, is_disciplinary, advisor_room FROM teachers WHERE teacher_id = ? LIMIT 1");
    $stmt->bind_param("s", $teacher_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'ไม่พบรหัสครูนี้ในระบบ'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $teacher = $res->fetch_assoc();
    $stored_password = $teacher['password'];
    $password_valid = false;

    if (password_get_info($stored_password)['algo'] !== null) {
        $password_valid = password_verify($password, $stored_password);
    } else {
        $password_valid = hash_equals($stored_password, $password);
    }

    if ($password_valid !== true) {
        echo json_encode(['success' => false, 'message' => 'รหัสผ่านไม่ถูกต้อง'], JSON_UNESCAPED_UNICODE);
        exit;
    }

    // Auto-migrate plain text -> bcrypt หลัง login สำเร็จ
    if (password_get_info($stored_password)['algo'] === null) {
        $new_hash = password_hash($password, PASSWORD_BCRYPT);
        $update = $conn->prepare("UPDATE teachers SET password = ? WHERE teacher_id = ?");
        $update->bind_param("ss", $new_hash, $teacher_id);
        $update->execute();
    }

    unset($teacher['password']);

    echo json_encode([
        'success' => true,
        'role'    => 'teacher',
        'teacher' => $teacher
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ กรุณาลองใหม่'], JSON_UNESCAPED_UNICODE);
}
