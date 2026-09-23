<?php
session_start();
include 'db.php';

$error = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $teacher_id = trim($_POST['teacher_id'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($teacher_id === '' || $password === '') {
        $error = "กรุณากรอกรหัสครูและรหัสผ่าน";
    } else {
        $stmt = $conn->prepare("SELECT * FROM teachers WHERE teacher_id = ?");
        $stmt->bind_param("s", $teacher_id);
        $stmt->execute();
        $res = $stmt->get_result();

        if ($res->num_rows === 0) {
            $error = "รหัสประจำตัวหรือรหัสผ่านไม่ถูกต้อง";
        } else {
            $teacher = $res->fetch_assoc();
            $db_pass = $teacher['password'];

            // รองรับทั้ง bcrypt hash และ plain text (ช่วง transition)
            $is_valid = password_verify($password, $db_pass) || hash_equals($db_pass, $password);

            if ($is_valid !== true) {
                $error = "รหัสประจำตัวหรือรหัสผ่านไม่ถูกต้อง";
            } else {
                // login สำเร็จ - set session ที่นี่ที่เดียว ไม่มี execute ซ้ำ
                $_SESSION['teacher_id'] = $teacher['teacher_id'];
                $_SESSION['teacher_name'] = $teacher['name'];

                // lazy migrate เป็น bcrypt ถ้ายังเป็น plain text
                if (password_get_info($db_pass)['algo'] === null) {
                    $new_hash = password_hash($password, PASSWORD_BCRYPT);
                    $update = $conn->prepare("UPDATE teachers SET password = ? WHERE teacher_id = ?");
                    $update->bind_param("ss", $new_hash, $teacher_id);
                    $update->execute();
                }

                header("Location: dashboard.php");
                exit();
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <title>เข้าสู่ระบบสำหรับครู</title>
    <style>
        body { font-family: Tahoma, sans-serif; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-box { background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); width: 300px; text-align: center; }
        input[type="text"], input[type="password"] { width: 90%; padding: 10px; margin: 10px 0; border: 1px solid #ccc; border-radius: 4px; }
        button { background-color: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; width: 100%; }
        button:hover { background-color: #45a049; }
        .error { color: red; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="login-box">
        <h2>Smart School Login</h2>
        <?php if(isset($error)) { echo "<p class='error'>$error</p>"; } ?>
        <form method="POST" action="">
            <input type="text" name="teacher_id" placeholder="รหัสประจำตัวครู (เช่น T001)" required>
            <input type="password" name="password" placeholder="รหัสผ่าน" required>
            <button type="submit">เข้าสู่ระบบ</button>
        </form>
    </div>
</body>
</html>