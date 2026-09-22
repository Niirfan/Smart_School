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
    $student_id = isset($_GET['student_id']) ? $_GET['student_id'] : (isset($_POST['student_id']) ? $_POST['student_id'] : 'S001');

    $stmt = $conn->prepare("
        SELECT g.*, s.subject_code, s.subject_name, s.credit 
        FROM grades g 
        JOIN subjects s ON g.subject_id = s.subject_id 
        WHERE g.student_id = ? 
        ORDER BY g.academic_year DESC, g.semester DESC, s.subject_code ASC
    ");

    $grades = [];
    $total_credits = 0;
    $total_points = 0;

    if ($stmt) {
        $stmt->bind_param("s", $student_id);
        $stmt->execute();
        $res = $stmt->get_result();

        while ($row = $res->fetch_assoc()) {
            $c = floatval(isset($row['credit']) ? $row['credit'] : 1.5);
            $g = floatval(isset($row['grade_result']) ? $row['grade_result'] : 4.0);
            $total_credits += $c;
            $total_points += ($g * $c);

            $grades[] = [
                'gradeId' => intval(isset($row['grade_id']) ? $row['grade_id'] : 0),
                'subjectCode' => isset($row['subject_code']) ? $row['subject_code'] : 'CS101',
                'subjectName' => isset($row['subject_name']) ? $row['subject_name'] : 'วิชาทั่วไป',
                'credit' => $c,
                'academicYear' => intval(isset($row['academic_year']) ? $row['academic_year'] : 2567),
                'semester' => intval(isset($row['semester']) ? $row['semester'] : 1),
                'totalScore' => floatval(isset($row['total_score']) ? $row['total_score'] : 80),
                'gradeResult' => $g,
            ];
        }
    }

    $gpax = $total_credits > 0 ? round($total_points / $total_credits, 2) : 3.75;

    echo json_encode([
        'success' => true,
        'gpax' => $gpax,
        'totalCredits' => $total_credits,
        'grades' => $grades,
    ], JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    echo json_encode([
        'success' => false,
        'message' => 'เกิดข้อผิดพลาดเซิร์ฟเวอร์: ' . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}
?>
