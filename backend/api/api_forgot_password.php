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
    $input      = json_decode(file_get_contents('php://input'), true);
    $student_id = isset($input['student_id']) ? trim(strtoupper($input['student_id'])) : '';
    $new_pass   = isset($input['new_password']) ? $input['new_password'] : '';

    if (empty($student_id) || empty($new_pass)) {
        echo json_encode([
            'success' => false,
            'message' => 'กรุณากรอกรหัสนักเรียนและรหัสผ่านใหม่'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (strlen($new_pass) < 6) {
        echo json_encode([
            'success' => false,
            'message' => 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $check = $conn->prepare("SELECT * FROM students WHERE student_id = ?");
    if (!$check) {
        throw new Exception("คำสั่ง SQL ตรวจสอบนักเรียนผิดพลาด: " . $conn->error);
    }
    $check->bind_param("s", $student_id);
    $check->execute();
    $res = $check->get_result();

    if ($res->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'ไม่พบรหัสนักเรียน "' . $student_id . '" ในระบบ'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $row = $res->fetch_assoc();

    $email = isset($input['email']) ? trim(strtolower($input['email'])) : '';

    if (empty($email)) {
        echo json_encode([
            'success' => false,
            'message' => 'กรุณายืนยันตัวตนด้วยบัญชี Google ก่อนทำการรีเซ็ตรหัสผ่าน'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (isset($row['email']) && !empty($row['email'])) {
        if (strtolower(trim($row['email'])) !== $email) {
            echo json_encode([
                'success' => false,
                'message' => 'บัญชี Google (' . $email . ') ไม่ตรงกับอีเมลที่ลงทะเบียนไว้ในระบบ'
            ], JSON_UNESCAPED_UNICODE);
            exit();
        }
    }

    $hashed = password_hash($new_pass, PASSWORD_BCRYPT);
    $stmt = $conn->prepare("UPDATE students SET password = ? WHERE student_id = ?");
    if (!$stmt) {
        throw new Exception("คำสั่ง SQL อัปเดตรหัสผ่านผิดพลาด: " . $conn->error);
    }
    $stmt->bind_param("ss", $hashed, $student_id);

    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'เปลี่ยนรหัสผ่านสำเร็จ',
            'name'    => isset($row['name']) ? $row['name'] : 'นักเรียน',
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
