<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$student_id = isset($_GET['student_id']) ? trim($_GET['student_id']) : 'S001';

// ดึงประวัติพฤติกรรมทั้งหมดของนักเรียน พร้อมชื่อครู
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
$stmt->bind_param("s", $student_id);
$stmt->execute();
$res = $stmt->get_result();

$records = [];
while ($row = $res->fetch_assoc()) {
    $records[] = [
        'title'        => $row['reason'] ?? 'บันทึกพฤติกรรม',
        'date'         => date('d/m/Y', strtotime($row['created_at'])),
        'recordedBy'   => $row['teacher_name'] ?? 'ไม่ระบุ',
        'pointsChange' => (int)$row['score_change'],
    ];
}

echo json_encode([
    'success' => true,
    'records' => $records
], JSON_UNESCAPED_UNICODE);
?>
