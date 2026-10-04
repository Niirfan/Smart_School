<?php
date_default_timezone_set('Asia/Bangkok');

// ปิดการ throw exception อัตโนมัติใน PHP 8.1+ ป้องกัน HTTP ERROR 500
mysqli_report(MYSQLI_REPORT_OFF);

$user = "6620310131"; 
$pass = "6620310131"; 
$dbname = "6620310131_smartschool_db";

// รายการ host ที่จะทดสอบเชื่อมต่อตามลำดับ
$hosts = ['172.18.111.42', 'localhost', '127.0.0.1'];

$conn = null;
$last_error = '';

foreach ($hosts as $h) {
    try {
        $c = @new mysqli($h, $user, $pass, $dbname);
        if ($c && !$c->connect_error) {
            $conn = $c;
            break;
        } else {
            if ($c) { $last_error = $c->connect_error; }
        }
    } catch (Throwable $e) {
        $last_error = $e->getMessage();
    }
}

if (!$conn || $conn->connect_error) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'เชื่อมต่อฐานข้อมูลไม่สำเร็จ: ' . ($last_error !== '' ? $last_error : 'Connection failed')
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

$conn->set_charset("utf8mb4");
?>