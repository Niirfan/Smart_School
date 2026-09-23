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
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method !== 'GET') {
        echo json_encode(['success' => false, 'message' => 'Method ไม่รองรับ'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    $room = isset($_GET['room']) ? trim($_GET['room']) : '';
    $teacher_id = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';

    if (empty($room) && empty($teacher_id)) {
        echo json_encode(['success' => false, 'message' => 'กรุณาระบุ room หรือ teacher_id'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if (!empty($room)) {
        // --- ดึงรายชื่อนักเรียนตามห้องที่ระบุตรงๆ ---
        $stmt = $conn->prepare("
            SELECT student_id, name, room, class_no, phone_number, blood_group
            FROM students WHERE room = ? ORDER BY class_no ASC
        ");
        $stmt->bind_param("s", $room);
        $stmt->execute();
        $res = $stmt->get_result();

        $students = [];
        while ($row = $res->fetch_assoc()) {
            $students[] = $row;
        }

        echo json_encode(['success' => true, 'room' => $room, 'students' => $students], JSON_UNESCAPED_UNICODE);

    } else {
        // --- ดึงรายชื่อนักเรียนทุกห้องที่ครูคนนี้มีสอน (จาก timetables) ---
        $stmt = $conn->prepare("SELECT DISTINCT room FROM timetables WHERE teacher_id = ?");
        $stmt->bind_param("s", $teacher_id);
        $stmt->execute();
        $res = $stmt->get_result();

        $rooms = [];
        while ($row = $res->fetch_assoc()) {
            $rooms[] = $row['room'];
        }

        if (empty($rooms)) {
            echo json_encode(['success' => true, 'rooms' => [], 'students_by_room' => []], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $placeholders = implode(',', array_fill(0, count($rooms), '?'));
        $types = str_repeat('s', count($rooms));

        $stmt = $conn->prepare("
            SELECT student_id, name, room, class_no, phone_number, blood_group
            FROM students WHERE room IN ($placeholders) ORDER BY room ASC, class_no ASC
        ");
        $stmt->bind_param($types, ...$rooms);
        $stmt->execute();
        $res = $stmt->get_result();

        // จัดกลุ่มตามห้อง ให้ Flutter render ง่ายขึ้น (accordion/section list)
        $students_by_room = [];
        while ($row = $res->fetch_assoc()) {
            $students_by_room[$row['room']][] = $row;
        }

        echo json_encode([
            'success' => true,
            'rooms' => $rooms,
            'students_by_room' => $students_by_room
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}