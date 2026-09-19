<?php
session_start();
if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>ระบบจัดการการเรียนการสอน</title>
    <style>
        body { font-family: Tahoma, sans-serif; margin: 0; padding: 20px; background: #f4f7f6; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .menu { display: flex; gap: 15px; margin-top: 20px; }
        .menu a { padding: 15px 20px; background: #008CBA; color: white; text-decoration: none; border-radius: 5px; text-align: center; flex: 1; }
        .menu a:hover { background: #007B9E; }
        .logout { background: #f44336 !important; }
    </style>
</head>
<body>
    <div class="container">
        <h2>ยินดีต้อนรับ, ครู<?php echo $_SESSION['teacher_name']; ?></h2>
        <p>กรุณาเลือกเมนูที่ต้องการทำรายการ</p>
        <div class="menu">
            <a href="subjects.php">📚 จัดการรายวิชา</a>
            <a href="grades.php">📝 บันทึกคะแนน/ตัดเกรด</a>
            <a href="logout.php" class="logout">🚪 ออกจากระบบ</a>
        </div>
    </div>
</body>
</html>