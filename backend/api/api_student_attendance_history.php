<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$student_id = trim($_GET['student_id'] ?? '');
if ($student_id === '') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'กรุณาระบุรหัสนักเรียน'], JSON_UNESCAPED_UNICODE);
    exit();
}

try {
    $stmt = $conn->prepare(
        'SELECT date, scan_in_time, scan_out_time, daily_status
         FROM daily_attendance
         WHERE student_id = ?
         ORDER BY date DESC
         LIMIT 90'
    );
    if (!$stmt) {
        throw new Exception('เตรียมคำสั่งอ่านประวัติเช็คชื่อไม่สำเร็จ');
    }

    $stmt->bind_param('s', $student_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $records = [];
    while ($row = $result->fetch_assoc()) {
        $records[] = [
            'date' => $row['date'],
            'scan_in_time' => $row['scan_in_time'],
            'scan_out_time' => $row['scan_out_time'],
            'daily_status' => $row['daily_status'],
        ];
    }

    echo json_encode(['success' => true, 'records' => $records], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'โหลดประวัติเช็คชื่อไม่สำเร็จ'], JSON_UNESCAPED_UNICODE);
}
?>
