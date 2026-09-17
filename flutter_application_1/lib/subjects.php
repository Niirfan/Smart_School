<?php
session_start();
include 'db.php';

if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}

// จัดการการเพิ่มวิชาใหม่
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['add_subject'])) {
    $sub_id = $_POST['subject_id'];
    $sub_code = $_POST['subject_code'];
    $sub_name = $_POST['subject_name'];
    $credit = $_POST['credit'];

    $stmt = $conn->prepare("INSERT INTO subjects (subject_id, subject_code, subject_name, credit) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("sssd", $sub_id, $sub_code, $sub_name, $credit);
    $stmt->execute();
    header("Location: subjects.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>จัดการรายวิชา</title>
    <style>
        body { font-family: Tahoma, sans-serif; padding: 20px; background: #f4f7f6; }
        .container { max-width: 900px; margin: auto; background: white; padding: 20px; border-radius: 8px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #f2f2f2; }
        .form-group { margin-bottom: 10px; }
        input[type="text"], input[type="number"] { padding: 8px; width: calc(100% - 20px); margin-top: 5px; }
        button { background-color: #4CAF50; color: white; padding: 10px; border: none; cursor: pointer; }
        .back-btn { background-color: #555; text-decoration: none; padding: 10px 15px; color: white; border-radius: 4px; display: inline-block; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <a href="dashboard.php" class="back-btn">กลับหน้าหลัก</a>
        <h2>เพิ่มรายวิชาใหม่</h2>
        <form method="POST" style="background:#f9f9f9; padding:15px; border:1px solid #ccc;">
            <div class="form-group">
                <label>Subject ID (เช่น SUB004):</label>
                <input type="text" name="subject_id" required>
            </div>
            <div class="form-group">
                <label>รหัสวิชา (เช่น ว21102):</label>
                <input type="text" name="subject_code" required>
            </div>
            <div class="form-group">
                <label>ชื่อวิชา:</label>
                <input type="text" name="subject_name" required>
            </div>
            <div class="form-group">
                <label>หน่วยกิต:</label>
                <input type="number" step="0.5" name="credit" required>
            </div>
            <button type="submit" name="add_subject">บันทึกรายวิชา</button>
        </form>

        <h2>รายวิชาทั้งหมด</h2>
        <table>
            <tr>
                <th>Subject ID</th>
                <th>รหัสวิชา</th>
                <th>ชื่อวิชา</th>
                <th>หน่วยกิต</th>
            </tr>
            <?php
            $result = $conn->query("SELECT * FROM subjects ORDER BY subject_id ASC");
            while($row = $result->fetch_assoc()) {
                echo "<tr>
                        <td>{$row['subject_id']}</td>
                        <td>{$row['subject_code']}</td>
                        <td>{$row['subject_name']}</td>
                        <td>{$row['credit']}</td>
                    </tr>";
            }
            ?>
        </table>
    </div>
</body>
</html>