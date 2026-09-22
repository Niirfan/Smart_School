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
    $room = isset($_GET['room']) ? $_GET['room'] : (isset($_GET['student_id']) ? 'ม.4/1' : 'ม.1/1');

    $timetable_by_day = [
        'Monday' => [],
        'Tuesday' => [],
        'Wednesday' => [],
        'Thursday' => [],
        'Friday' => [],
    ];

    $stmt = $conn->prepare("
        SELECT tt.*, s.subject_code, s.subject_name, s.credit, t.name as teacher_name 
        FROM timetables tt 
        JOIN subjects s ON tt.subject_id = s.subject_id 
        JOIN teachers t ON tt.teacher_id = t.teacher_id 
        WHERE tt.room = ? 
        ORDER BY FIELD(tt.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'), tt.start_time ASC
    ");

    if ($stmt) {
        $stmt->bind_param("s", $room);
        $stmt->execute();
        $res = $stmt->get_result();

        while ($row = $res->fetch_assoc()) {
            $day = $row['day_of_week'];
            $item = [
                'scheduleId' => isset($row['schedule_id']) ? $row['schedule_id'] : 0,
                'timeRange' => substr($row['start_time'], 0, 5) . ' - ' . substr($row['end_time'], 0, 5) . ' น.',
                'room' => 'ห้อง ' . (isset($row['room']) ? $row['room'] : $room),
                'subjectCode' => isset($row['subject_code']) ? $row['subject_code'] : 'TH101',
                'subjectName' => isset($row['subject_name']) ? $row['subject_name'] : 'วิชาทั่วไป',
                'credit' => floatval(isset($row['credit']) ? $row['credit'] : 1.5),
                'teacherName' => isset($row['teacher_name']) ? $row['teacher_name'] : 'ครูผู้สอน',
            ];

            if (isset($timetable_by_day[$day])) {
                $timetable_by_day[$day][] = $item;
            } else {
                $timetable_by_day[$day] = [$item];
            }
        }
    }

    echo json_encode([
        'success' => true,
        'room' => $room,
        'timetable' => $timetable_by_day
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
