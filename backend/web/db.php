<?php
date_default_timezone_set('Asia/Bangkok');

// กำหนดค่าการเชื่อมต่อฐานข้อมูล
$host = "172.18.111.42"; 
$user = "6620310131"; 
$pass = "6620310131"; 
$dbname = "6620310131_smartschool_db";

// ลองเชื่อมต่อ localhost ก่อน (กรณีรันบน Server เครื่องเดียวกัน)
$conn = @new mysqli($host, $user, $pass, $dbname);

// ถ้า localhost ไม่ได้ ให้ลองเชื่อมต่อผ่าน IP 172.18.111.42
if ($conn->connect_error) {
    $conn = @new mysqli("172.18.111.42", $user, $pass, $dbname);
}

if ($conn->connect_error) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'เชื่อมต่อฐานข้อมูลไม่สำเร็จ: ' . $conn->connect_error
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

$conn->set_charset("utf8mb4");
?>