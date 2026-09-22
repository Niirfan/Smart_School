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
    $student_id = isset($_GET['student_id']) ? trim($_GET['student_id']) : 'S001';

    $records = [];
    $stmt = $conn->prepare("
        SELECT 
            b.behavior_id,
            b.score_change,
            b.reason,
            b.created_at,
            t.name AS teacher_name
        FROM behaviors b
        LEFT JOIN teachers t ON b.teacher_id = t.teacher_id
        WHERE b.student_id = ?
        ORDER BY b.created_at DESC
    ");

    if ($stmt) {
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $res = $stmt->get_result();

        while ($row = $res->fetch_assoc()) {
            $records[] = [
                'title'        => isset($row['reason']) && !empty($row['reason']) ? $row['reason'] : 'บันทึกพฤติกรรม',
                'date'         => date('d/m/Y', strtotime(isset($row['created_at']) ? $row['created_at'] : 'now')),
                'recordedBy'   => isset($row['teacher_name']) && !empty($row['teacher_name']) ? $row['teacher_name'] : 'ครูประจำวิชา',
                'pointsChange' => (int)(isset($row['score_change']) ? $row['score_change'] : 0),
            ];
        }
    }

    echo json_encode([
        'success' => true,
        'records' => $records
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
