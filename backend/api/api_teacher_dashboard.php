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
    $teacher_id = isset($_GET['teacher_id']) ? trim($_GET['teacher_id']) : '';

    if (empty($teacher_id)) {
        echo json_encode(['success' => false, 'message' => 'กรุณาระบุรหัสครู'], JSON_UNESCAPED_UNICODE);
        exit();
    }

    // --- 1. ข้อมูลครู ---
    $stmt = $conn->prepare("SELECT teacher_id, name, department, phone_number, address, blood_group, is_disciplinary FROM teachers WHERE teacher_id = ?");
    $stmt->bind_param("s", $teacher_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'ไม่พบข้อมูลครู'], JSON_UNESCAPED_UNICODE);
        exit();
    }
    $teacher = $res->fetch_assoc();

    // --- 2. ตารางสอนวันนี้ (ตาม day_of_week ปัจจุบัน) ---
    // แปลงวันอังกฤษจาก PHP ให้ตรงกับ enum ในตาราง timetables
    $today_en = date('l'); // เช่น 'Monday'

    $stmt = $conn->prepare("
        SELECT t.schedule_id, t.subject_id, s.subject_name, s.subject_code, t.room, t.start_time, t.end_time
        FROM timetables t
        JOIN subjects s ON t.subject_id = s.subject_id
        WHERE t.teacher_id = ? AND t.day_of_week = ?
        ORDER BY t.start_time ASC
    ");
    $stmt->bind_param("ss", $teacher_id, $today_en);
    $stmt->execute();
    $res = $stmt->get_result();
    $today_schedule = [];
    while ($row = $res->fetch_assoc()) {
        $today_schedule[] = $row;
    }

    // --- 3. สรุปสถิติ: จำนวนคาบสอนวันนี้ ---
    $periods_today = count($today_schedule);

    // --- 4. จำนวนนักเรียนทั้งหมดที่ครูดูแล (รวมทุกห้องที่สอนวันนี้ ไม่ซ้ำ) ---
    $students_count = 0;
    if ($periods_today > 0) {
        $rooms = array_unique(array_column($today_schedule, 'room'));
        $placeholders = implode(',', array_fill(0, count($rooms), '?'));
        $types = str_repeat('s', count($rooms));

        $stmt = $conn->prepare("SELECT COUNT(*) as cnt FROM students WHERE room IN ($placeholders)");
        $stmt->bind_param($types, ...$rooms);
        $stmt->execute();
        $res = $stmt->get_result();
        $students_count = $res->fetch_assoc()['cnt'];
    }

    // --- 5. จำนวนนักเรียนที่ยังไม่เช็คชื่อวันนี้ (daily_attendance) ---
    $today_date = date('Y-m-d');
    $not_checked_in = 0;
    if ($periods_today > 0 && !empty($rooms)) {
        $placeholders = implode(',', array_fill(0, count($rooms), '?'));
        $types = str_repeat('s', count($rooms)) . 's';
        $params = array_merge($rooms, [$today_date]);

        $stmt = $conn->prepare("
            SELECT COUNT(*) as cnt FROM students st
            WHERE st.room IN ($placeholders)
            AND st.student_id NOT IN (
                SELECT student_id FROM daily_attendance WHERE date = ?
            )
        ");
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $res = $stmt->get_result();
        $not_checked_in = $res->fetch_assoc()['cnt'];
    }

    echo json_encode([
        'success' => true,
        'teacher' => $teacher,
        'today_schedule' => $today_schedule,
        'stats' => [
            'periods_today' => $periods_today,
            'students_count' => (int)$students_count,
            'not_checked_in_today' => (int)$not_checked_in
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}