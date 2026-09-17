<?php
$host = "172.18.111.42"; // หรือ IP ของ Server คุณ เช่น 172.18.111.43
$user = "6620310131"; // เปลี่ยนเป็น username ของฐานข้อมูล
$pass = "6620310131"; // เปลี่ยนเป็น password ของฐานข้อมูล
$dbname = "6620310131_smartschool_db";

$conn = new mysqli($host, $user, $pass, $dbname);
$conn->set_charset("utf8mb4");

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>