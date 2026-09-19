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
$student_id = isset($input['student_id']) ? $input['student_id'] : (isset($_POST['student_id']) ? $_POST['student_id'] : '');
$password = isset($input['password']) ? $input['password'] : (isset($_POST['password']) ? $_POST['password'] : '');

if (empty($student_id) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'กรุณากรอกรหัสนักเรียนและรหัสผ่าน'
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

$stmt = $conn->prepare("SELECT * FROM students WHERE student_id = ? AND password = ?");
$stmt->bind_param("ss", $student_id, $password);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows > 0) {
    $student = $res->fetch_assoc();
    unset($student['password']); // ไม่ส่งรหัสผ่านกลับไป
    echo json_encode([
        'success' => true,
        'message' => 'เข้าสู่ระบบสำเร็จ',
        'student' => $student
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'รหัสนักเรียนหรือรหัสผ่านไม่ถูกต้อง'
    ], JSON_UNESCAPED_UNICODE);
}
?>
