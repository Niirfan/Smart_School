<?php
session_start();
include 'db.php';

if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['save_grade'])) {
    // รับค่ามาจากฟอร์ม (ไม่มี grade_id แล้ว)
    $student_id = $_POST['student_id'];
    $subject_id = $_POST['subject_id'];
    $academic_year = $_POST['academic_year'];
    $semester = $_POST['semester'];
    $total_score = $_POST['total_score'];

    // ระบบตัดเกรด
    $grade_result = 0;
    if ($total_score >= 80) $grade_result = 4.0;
    elseif ($total_score >= 75) $grade_result = 3.5;
    elseif ($total_score >= 70) $grade_result = 3.0;
    elseif ($total_score >= 65) $grade_result = 2.5;
    elseif ($total_score >= 60) $grade_result = 2.0;
    elseif ($total_score >= 55) $grade_result = 1.5;
    elseif ($total_score >= 50) $grade_result = 1.0;
    else $grade_result = 0.0;

    // คำสั่ง SQL เอา grade_id ออก ปล่อยให้ฐานข้อมูลรันเอง
    $stmt = $conn->prepare("INSERT INTO grades (student_id, subject_id, academic_year, semester, total_score, grade_result) VALUES (?, ?, ?, ?, ?, ?)");
    
    if ($stmt) {
        $stmt->bind_param("ssssdd", $student_id, $subject_id, $academic_year, $semester, $total_score, $grade_result);
        if($stmt->execute()) {
            header("Location: grades.php");
            exit();
        } else {
            $error_msg = "เกิดข้อผิดพลาดในการบันทึก: " . $stmt->error;
        }
    } else {
        $error_msg = "เกิดข้อผิดพลาดในการเตรียม SQL: " . $conn->error;
    }
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>บันทึกคะแนนและตัดเกรด</title>
    <style>
        body { font-family: Tahoma, sans-serif; padding: 20px; background: #f4f7f6; }
        .container { max-width: 900px; margin: auto; background: white; padding: 20px; border-radius: 8px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; }
        .form-group { margin-bottom: 10px; }
        input[type="text"], input[type="number"] { padding: 8px; width: calc(100% - 20px); margin-top: 5px; }
        button { background-color: #4CAF50; color: white; padding: 10px; border: none; cursor: pointer; margin-top: 10px; }
        .back-btn { background-color: #555; text-decoration: none; padding: 10px 15px; color: white; border-radius: 4px; display: inline-block; margin-bottom: 20px; }
        .error { color: red; margin-bottom: 15px; font-weight: bold; }
        .form-row { display: flex; gap: 10px; }
        .form-row .form-group { flex: 1; }
    </style>
</head>
<body>
    <div class="container">
        <a href="dashboard.php" class="back-btn">กลับหน้าหลัก</a>
        <h2>บันทึกคะแนนและตัดเกรด</h2>
        
        <?php if(isset($error_msg)) { echo "<div class='error'>$error_msg</div>"; } ?>

        <form method="POST" style="background:#f9f9f9; padding:15px; border:1px solid #ccc;">
            <div class="form-row">
                <div class="form-group">
                    <label>รหัสนักเรียน:</label>
                    <input type="text" name="student_id" placeholder="เช่น S001" required>
                </div>
                <div class="form-group">
                    <label>รหัสวิชาอ้างอิง (Subject ID):</label>
                    <input type="text" name="subject_id" placeholder="เช่น SUB001" required>
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label>ปีการศึกษา:</label>
                    <input type="text" name="academic_year" placeholder="เช่น 2567" required>
                </div>
                <div class="form-group">
                    <label>ภาคเรียน:</label>
                    <input type="text" name="semester" placeholder="เช่น 1 หรือ 2" required>
                </div>
            </div>

            <div class="form-group">
                <label>คะแนนดิบรวม (0-100):</label>
                <input type="number" name="total_score" min="0" max="100" required>
            </div>
            <button type="submit" name="save_grade">บันทึกคะแนนและตัดเกรด</button>
        </form>

        <h2>ข้อมูลคะแนนล่าสุด</h2>
        <table>
            <tr>
                <th>ลำดับ (ID)</th>
                <th>รหัสนักเรียน</th>
                <th>Subject ID</th>
                <th>ปีการศึกษา</th>
                <th>ภาคเรียน</th>
                <th>คะแนนรวม</th>
                <th>เกรดที่ได้</th>
            </tr>
            <?php
            $result = $conn->query("SELECT * FROM grades ORDER BY grade_id DESC");
            if ($result && $result->num_rows > 0) {
                while($row = $result->fetch_assoc()) {
                    echo "<tr>
                            <td>{$row['grade_id']}</td>
                            <td>{$row['student_id']}</td>
                            <td>{$row['subject_id']}</td>
                            <td>{$row['academic_year']}</td>
                            <td>{$row['semester']}</td>
                            <td>{$row['total_score']}</td>
                            <td><strong>{$row['grade_result']}</strong></td>
                          </tr>";
                }
            } else {
                echo "<tr><td colspan='7' style='text-align:center;'>ยังไม่มีข้อมูลคะแนน</td></tr>";
            }
            ?>
        </table>
    </div>
</body>
</html>