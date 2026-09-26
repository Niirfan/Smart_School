<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

try {
    $teacher_id = trim($_GET['teacher_id'] ?? '');
    $date = trim($_GET['date'] ?? date('Y-m-d'));

    if ($teacher_id === '' || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'ข้อมูล teacher_id หรือ date ไม่ถูกต้อง'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $teacher_stmt = $conn->prepare('SELECT teacher_id, name FROM teachers WHERE teacher_id = ? LIMIT 1');
    $teacher_stmt->bind_param('s', $teacher_id);
    $teacher_stmt->execute();
    if ($teacher_stmt->get_result()->num_rows === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'ไม่พบข้อมูลครู'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $day_of_week = date('l', strtotime($date));
    $stmt = $conn->prepare(
        'SELECT t.schedule_id, s.subject_name, s.subject_code, t.room,
                t.start_time, t.end_time, tc.name AS teacher_name
         FROM timetables t
         JOIN subjects s ON t.subject_id = s.subject_id
         JOIN teachers tc ON t.teacher_id = tc.teacher_id
         WHERE t.teacher_id = ? AND t.day_of_week = ?
         ORDER BY t.start_time ASC'
    );
    $stmt->bind_param('ss', $teacher_id, $day_of_week);
    $stmt->execute();

    $now = date('H:i:s');
    $today = date('Y-m-d') === $date;
    $schedule = [];
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $status = 'normal';
        if ($today && $now >= $row['start_time'] && $now <= $row['end_time']) {
            $status = 'inProgress';
        } elseif ($today && $now < $row['start_time']) {
            $status = 'upcoming';
        }
        $schedule[] = [
            'scheduleId' => $row['schedule_id'],
            'timeRange' => substr($row['start_time'], 0, 5) . ' - ' . substr($row['end_time'], 0, 5) . ' น.',
            'room' => $row['room'],
            'subjectName' => $row['subject_name'],
            'teacherName' => $row['teacher_name'],
            'status' => $status,
            'subjectCode' => $row['subject_code'],
        ];
    }

    echo json_encode([
        'success' => true,
        'date' => $date,
        'dayOfWeek' => $day_of_week,
        'schedule' => $schedule,
    ], JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    error_log($e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}
