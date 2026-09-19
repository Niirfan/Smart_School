<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

include 'db.php';

$student_id = isset($_GET['student_id']) ? $_GET['student_id'] : (isset($_POST['student_id']) ? $_POST['student_id'] : 'S001');

$stmt = $conn->prepare("
    SELECT g.*, s.subject_code, s.subject_name, s.credit 
    FROM grades g 
    JOIN subjects s ON g.subject_id = s.subject_id 
    WHERE g.student_id = ? 
    ORDER BY g.academic_year DESC, g.semester DESC, s.subject_code ASC
");
$stmt->bind_param("s", $student_id);
$stmt->execute();
$res = $stmt->get_result();

$grades = [];
$total_credits = 0;
$total_points = 0;

while ($row = $res->fetch_assoc()) {
    $c = floatval($row['credit']);
    $g = floatval($row['grade_result']);
    $total_credits += $c;
    $total_points += ($g * $c);

    $grades[] = [
        'gradeId' => intval($row['grade_id']),
        'subjectCode' => $row['subject_code'],
        'subjectName' => $row['subject_name'],
        'credit' => $c,
        'academicYear' => intval($row['academic_year']),
        'semester' => intval($row['semester']),
        'totalScore' => floatval($row['total_score']),
        'gradeResult' => $g,
    ];
}

$gpax = $total_credits > 0 ? round($total_points / $total_credits, 2) : 3.78;

echo json_encode([
    'success' => true,
    'gpax' => $gpax,
    'totalCredits' => $total_credits,
    'grades' => $grades,
], JSON_UNESCAPED_UNICODE);
?>
