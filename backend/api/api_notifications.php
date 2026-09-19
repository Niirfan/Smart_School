<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$student_id = isset($_GET['student_id']) ? $_GET['student_id'] : 'S001';

$stmt = $conn->prepare("SELECT * FROM notifications WHERE student_id = ? ORDER BY created_at DESC");
$stmt->bind_param("s", $student_id);
$stmt->execute();
$res = $stmt->get_result();

$notifications = [];
while ($row = $res->fetch_assoc()) {
    $notifications[] = [
        'id' => $row['notification_id'],
        'title' => $row['title'],
        'message' => $row['message'],
        'createdAt' => date('d M Y H:i', strtotime($row['created_at'])),
    ];
}

echo json_encode([
    'success' => true,
    'notifications' => $notifications
], JSON_UNESCAPED_UNICODE);
?>
