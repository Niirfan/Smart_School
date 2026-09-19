<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$room = isset($_GET['room']) ? $_GET['room'] : 'ม.1/1';

$stmt = $conn->prepare("
    SELECT tt.*, s.subject_code, s.subject_name, s.credit, t.name as teacher_name 
    FROM timetables tt 
    JOIN subjects s ON tt.subject_id = s.subject_id 
    JOIN teachers t ON tt.teacher_id = t.teacher_id 
    WHERE tt.room = ? 
    ORDER BY FIELD(tt.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), tt.start_time ASC
");
$stmt->bind_param("s", $room);
$stmt->execute();
$res = $stmt->get_result();

$timetable_by_day = [
    'Monday' => [],
    'Tuesday' => [],
    'Wednesday' => [],
    'Thursday' => [],
    'Friday' => [],
];

while ($row = $res->fetch_assoc()) {
    $day = $row['day_of_week'];
    $item = [
        'scheduleId' => $row['schedule_id'],
        'timeRange' => substr($row['start_time'], 0, 5) . ' - ' . substr($row['end_time'], 0, 5) . ' น.',
        'room' => 'ห้อง ' . $row['room'],
        'subjectCode' => $row['subject_code'],
        'subjectName' => $row['subject_name'],
        'credit' => floatval($row['credit']),
        'teacherName' => $row['teacher_name'],
    ];

    if (isset($timetable_by_day[$day])) {
        $timetable_by_day[$day][] = $item;
    } else {
        $timetable_by_day[$day] = [$item];
    }
}

echo json_encode([
    'success' => true,
    'room' => $room,
    'timetable' => $timetable_by_day
], JSON_UNESCAPED_UNICODE);
?>
