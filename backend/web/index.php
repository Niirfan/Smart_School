<?php
require_once __DIR__ . '/session.php';
include 'db.php';

$error = '';

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $teacher_id = strtoupper(trim($_POST['teacher_id'] ?? ''));
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

            // รองรับทั้ง bcrypt hash และ plain text
            $is_valid = false;
            if (password_get_info($db_pass)['algo'] !== null) {
                $is_valid = password_verify($password, $db_pass);
            } else {
                $is_valid = ($password === $db_pass);
            }

            if ($is_valid !== true) {
                $error = "รหัสประจำตัวหรือรหัสผ่านไม่ถูกต้อง";
            } else {
                $_SESSION['teacher_id'] = $teacher['teacher_id'];
                $_SESSION['teacher_name'] = $teacher['name'];

                // lazy migrate เป็น bcrypt ถ้ายังเป็น plain text
                if (password_get_info($db_pass)['algo'] === null) {
                    $new_hash = password_hash($password, PASSWORD_BCRYPT);
                    $update = $conn->prepare("UPDATE teachers SET password = ? WHERE teacher_id = ?");
                    $update->bind_param("ss", $new_hash, $teacher_id);
                    $update->execute();
                }

                session_write_close();
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>เข้าสู่ระบบสำหรับครู - Smart School</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Sarabun', sans-serif; }
        body {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .login-card {
            background: rgba(255, 255, 255, 0.96);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            width: 100%;
            max-width: 420px;
            padding: 40px 35px;
            text-align: center;
        }
        .brand-icon {
            width: 70px;
            height: 70px;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: white;
            border-radius: 18px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            margin: 0 auto 20px;
            box-shadow: 0 10px 20px rgba(37, 99, 235, 0.3);
        }
        h2 { font-size: 24px; font-weight: 700; color: #1e293b; margin-bottom: 8px; }
        p.subtitle { color: #64748b; font-size: 14px; margin-bottom: 28px; }
        .alert-error {
            background-color: #fef2f2;
            border-left: 4px solid #ef4444;
            color: #991b1b;
            padding: 12px 16px;
            border-radius: 8px;
            font-size: 14px;
            margin-bottom: 20px;
            text-align: left;
        }
        .form-group { text-align: left; margin-bottom: 20px; }
        label { display: block; font-size: 14px; font-weight: 600; color: #334155; margin-bottom: 6px; }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 12px 16px;
            font-size: 15px;
            border: 1.5px solid #cbd5e1;
            border-radius: 10px;
            outline: none;
            transition: all 0.2s;
            background: #f8fafc;
        }
        input[type="text"]:focus, input[type="password"]:focus {
            border-color: #2563eb;
            background: #ffffff;
            box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1);
        }
        button.btn-login {
            width: 100%;
            padding: 14px;
            font-size: 16px;
            font-weight: 600;
            color: white;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            border: none;
            border-radius: 10px;
            cursor: pointer;
            transition: all 0.2s;
            box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
            margin-top: 10px;
        }
        button.btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 16px rgba(37, 99, 235, 0.4);
        }
        .footer-note { font-size: 13px; color: #94a3b8; margin-top: 24px; }
    </style>
</head>
<body>
    <div class="login-card">
        <div class="brand-icon">🏫</div>
        <h2>Smart School Web Portal</h2>
        <p class="subtitle">ระบบจัดการการเรียนการสอนสำหรับครูผู้สอน</p>

        <?php if (!empty($error)): ?>
            <div class="alert-error">
                ⚠️ <?php echo htmlspecialchars($error); ?>
            </div>
        <?php endif; ?>

        <form method="POST" action="">
            <div class="form-group">
                <label for="teacher_id">รหัสประจำตัวครู</label>
                <input type="text" id="teacher_id" name="teacher_id" placeholder="เช่น T001" required value="<?php echo htmlspecialchars($_POST['teacher_id'] ?? ''); ?>">
            </div>
            <div class="form-group">
                <label for="password">รหัสผ่าน</label>
                <input type="password" id="password" name="password" placeholder="กรอกรหัสผ่าน" required>
            </div>
            <button type="submit" class="btn-login">เข้าสู่ระบบ ➔</button>
        </form>

        <div class="footer-note">Smart School Management System © 2026</div>
    </div>
</body>
</html>
