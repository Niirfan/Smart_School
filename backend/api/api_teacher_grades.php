<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

// --- แปลงคะแนนรวมเป็นเกรด ตามเกณฑ์ที่ระบุในแผน ---
function calculateGrade($score) {
    if ($score >= 80) return '4';
    if ($score >= 75) return '3.5';
    if ($score >= 70) return '3';
    if ($score >= 65) return '2.5';
    if ($score >= 60) return '2';
    if ($score >= 55) return '1.5';
    if ($score >= 50) return '1';
    return '0';
}

try {
    $method = $_SERVER['REQUEST_METHOD'];

    if ($method === 'POST') {
        // --- บันทึก/แก้ไขคะแนนรายวิชา (รองรับบันทึกทีละหลายคน) ---
        $input = json_decode(file_get_contents('php://input'), true);

        $subject_id = trim($input['subject_id'] ?? '');
        $academic_year = isset($input['academic_year']) ? (int)$input['academic_year'] : null;
        $semester = isset($input['semester']) ? (int)$input['semester'] : null;
        $records = $input['records'] ?? []; // [{student_id, total_score}, ...]

        if (empty($subject_id) || $academic_year === null || $semester === null || empty($records) || !is_array($records)) {
            echo json_encode(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $conn->begin_transaction();

        // ใช้ ON DUPLICATE KEY UPDATE เพราะมี unique key (student_id, subject_id, academic_year, semester)
        // ทำให้บันทึกซ้ำ = อัปเดตคะแนนเดิม ไม่สร้างแถวซ้ำ
        $stmt = $conn->prepare("
            INSERT INTO grades (student_id, subject_id, academic_year, semester, total_score, grade_result)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE total_score = VALUES(total_score), grade_result = VALUES(grade_result)
        ");

        $saved_count = 0;
        foreach ($records as $rec) {
            $student_id = trim($rec['student_id'] ?? '');
            $total_score = isset($rec['total_score']) ? (float)$rec['total_score'] : null;

            if (empty($student_id) || $total_score === null) continue;
            if ($total_score < 0 || $total_score > 100) continue; // กันคะแนนผิดช่วง

            $grade_result = calculateGrade($total_score);

            $stmt->bind_param("ssiids", $student_id, $subject_id, $academic_year, $semester, $total_score, $grade_result);
            $stmt->execute();
            $saved_count++;
        }

        $conn->commit();

        echo json_encode([
            'success' => true,
            'message' => "บันทึกคะแนนสำเร็จ $saved_count รายการ"
        ], JSON_UNESCAPED_UNICODE);

    } elseif ($method === 'GET') {
        // --- ดึงรายชื่อนักเรียน + คะแนนปัจจุบัน ตามวิชา/ห้อง/ปี/เทอม ---
        $subject_id = isset($_GET['subject_id']) ? trim($_GET['subject_id']) : '';
        $room = isset($_GET['room']) ? trim($_GET['room']) : '';
        $academic_year = isset($_GET['academic_year']) ? (int)$_GET['academic_year'] : null;
        $semester = isset($_GET['semester']) ? (int)$_GET['semester'] : null;

        if (empty($subject_id) || empty($room) || $academic_year === null || $semester === null) {
            echo json_encode(['success' => false, 'message' => 'กรุณาระบุ subject_id, room, academic_year, semester ให้ครบ'], JSON_UNESCAPED_UNICODE);
            exit();
        }

        $stmt = $conn->prepare("
            SELECT st.student_id, st.name, st.class_no,
                   g.total_score, g.grade_result
            FROM students st
            LEFT JOIN grades g
                ON st.student_id = g.student_id
                AND g.subject_id = ?
                AND g.academic_year = ?
                AND g.semester = ?
            WHERE st.room = ?
            ORDER BY st.class_no ASC
        ");
        $stmt->bind_param("siis", $subject_id, $academic_year, $semester, $room);
        $stmt->execute();
        $res = $stmt->get_result();

        $students = [];
        while ($row = $res->fetch_assoc()) {
            $students[] = $row;
        }

        echo json_encode(['success' => true, 'students' => $students], JSON_UNESCAPED_UNICODE);

    } else {
        echo json_encode(['success' => false, 'message' => 'Method ไม่รองรับ'], JSON_UNESCAPED_UNICODE);
    }

} catch (Throwable $e) {
    $conn->rollback();
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => 'เกิดข้อผิดพลาดในระบบ'], JSON_UNESCAPED_UNICODE);
}