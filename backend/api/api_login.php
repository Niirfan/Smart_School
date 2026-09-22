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
    $student_id = isset($input['student_id']) ? trim($input['student_id']) : (isset($_POST['student_id']) ? trim($_POST['student_id']) : '');
    $password = isset($input['password']) ? $input['password'] : (isset($_POST['password']) ? $_POST['password'] : '');

    if (empty($student_id) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'กรุณากรอกรหัสนักเรียนและรหัสผ่าน'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $stmt = $conn->prepare("SELECT * FROM students WHERE student_id = ?");
    if (!$stmt) {
        throw new Exception("คำสั่ง SQL ผิดพลาด: " . $conn->error);
    }

    $stmt->bind_param("s", $student_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'ไม่พบรหัสนักเรียน "' . $student_id . '" ในระบบ'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $student = $res->fetch_assoc();

    // ตรวจสอบรหัสผ่าน (รองรับทั้ง BCRYPT HASH และ PLAIN TEXT)
    $db_pass = $student['password'];
    $is_valid = password_verify($password, $db_pass) || ($password === $db_pass);

    if (!$is_valid) {
        echo json_encode([
            'success' => false,
            'message' => 'รหัสผ่านไม่ถูกต้อง'
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    unset($student['password']); // ซ่อนรหัสผ่านไม่ส่งกลับไป

    echo json_encode([
        'success' => true,
        'message' => 'เข้าสู่ระบบสำเร็จ',
        'student' => $student
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
