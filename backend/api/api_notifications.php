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
    $student_id = isset($_GET['student_id']) ? $_GET['student_id'] : 'S001';

    $notifications = [];
    $stmt = $conn->prepare("SELECT * FROM notifications WHERE student_id = ? ORDER BY created_at DESC");
    if ($stmt) {
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $res = $stmt->get_result();

        while ($row = $res->fetch_assoc()) {
            $notifications[] = [
                'id' => isset($row['notification_id']) ? $row['notification_id'] : 1,
                'title' => isset($row['title']) ? $row['title'] : 'แจ้งเตือน',
                'message' => isset($row['message']) ? $row['message'] : 'ไม่มีรายละเอียด',
                'createdAt' => date('d M Y H:i', strtotime(isset($row['created_at']) ? $row['created_at'] : 'now')),
            ];
        }
    }

    echo json_encode([
        'success' => true,
        'notifications' => $notifications
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
