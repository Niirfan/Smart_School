<?php
require_once __DIR__ . '/session.php';
include 'db.php';

if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}

$msg = $_SESSION['msg'] ?? '';
$msg_type = $_SESSION['msg_type'] ?? '';
unset($_SESSION['msg'], $_SESSION['msg_type']);

// จัดการการเพิ่มวิชาใหม่
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['add_subject'])) {
    $sub_id = trim($_POST['subject_id'] ?? '');
    $sub_code = trim($_POST['subject_code'] ?? '');
    $sub_name = trim($_POST['subject_name'] ?? '');
    $credit = floatval($_POST['credit'] ?? 0);

    if ($sub_id === '' || $sub_code === '' || $sub_name === '' || $credit <= 0) {
        $_SESSION['msg'] = "กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง (หน่วยกิตต้องมากกว่า 0)";
        $_SESSION['msg_type'] = "error";
    } else {
        // เช็คว่า subject_id ซ้ำหรือไม่
        $check = $conn->prepare("SELECT subject_id FROM subjects WHERE subject_id = ?");
        $check->bind_param("s", $sub_id);
        $check->execute();
        if ($check->get_result()->num_rows > 0) {
            $_SESSION['msg'] = "รหัสอ้างอิง Subject ID ($sub_id) มีอยู่ในระบบแล้ว";
            $_SESSION['msg_type'] = "error";
        } else {
            $stmt = $conn->prepare("INSERT INTO subjects (subject_id, subject_code, subject_name, credit) VALUES (?, ?, ?, ?)");
            $stmt->bind_param("sssd", $sub_id, $sub_code, $sub_name, $credit);
            if ($stmt->execute()) {
                $_SESSION['msg'] = "บันทึกรายวิชา ($sub_code - $sub_name) เรียบร้อยแล้ว!";
                $_SESSION['msg_type'] = "success";
            } else {
                $_SESSION['msg'] = "เกิดข้อผิดพลาดในการบันทึก: " . $stmt->error;
                $_SESSION['msg_type'] = "error";
            }
        }
    }
    header("Location: subjects.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>จัดการรายวิชา - Smart School Web Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Sarabun', sans-serif; }
        body { background-color: #f1f5f9; color: #1e293b; min-height: 100vh; padding-bottom: 40px; }
        .navbar {
            background: #ffffff;
            border-bottom: 1px solid #e2e8f0;
            padding: 16px 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .navbar-brand { display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 20px; color: #0f172a; text-decoration: none; }
        .navbar-brand .icon { background: #2563eb; color: white; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 20px; }
        
        .container { max-width: 1000px; margin: 32px auto; padding: 0 20px; }
        .back-link { display: inline-flex; align-items: center; gap: 6px; text-decoration: none; color: #64748b; font-weight: 600; margin-bottom: 20px; transition: color 0.2s; }
        .back-link:hover { color: #2563eb; }

        .card { background: white; border-radius: 16px; border: 1px solid #e2e8f0; padding: 28px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.04); margin-bottom: 28px; }
        .card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
        .card-header h2 { font-size: 20px; font-weight: 700; color: #0f172a; display: flex; align-items: center; gap: 10px; }

        .alert {
            padding: 14px 18px;
            border-radius: 10px;
            font-size: 15px;
            margin-bottom: 24px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-success { background-color: #f0fdf4; border: 1px solid #bbf7d0; color: #166534; }
        .alert-error { background-color: #fef2f2; border: 1px solid #fecaca; color: #991b1b; }

        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
        .form-group { text-align: left; }
        label { display: block; font-size: 14px; font-weight: 600; color: #334155; margin-bottom: 6px; }
        input[type="text"], input[type="number"] {
            width: 100%;
            padding: 11px 14px;
            font-size: 14px;
            border: 1.5px solid #cbd5e1;
            border-radius: 8px;
            outline: none;
            background: #f8fafc;
            transition: all 0.2s;
        }
        input[type="text"]:focus, input[type="number"]:focus {
            border-color: #2563eb;
            background: #ffffff;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        .btn-submit {
            grid-column: 1 / -1;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: white;
            border: none;
            padding: 12px 24px;
            font-size: 15px;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 8px;
        }
        .btn-submit:hover { opacity: 0.95; transform: translateY(-1px); }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid #e2e8f0; font-size: 14.5px; }
        th { background-color: #f8fafc; font-weight: 600; color: #475569; }
        tr:hover { background-color: #f8fafc; }
        .badge-code { background: #eff6ff; color: #1d4ed8; padding: 4px 10px; border-radius: 6px; font-weight: 600; font-size: 13px; display: inline-block; }
        .empty-state { text-align: center; padding: 40px 20px; color: #94a3b8; }
        .empty-state .icon { font-size: 40px; margin-bottom: 10px; }
    </style>
</head>
<body>
    <header class="navbar">
        <a href="dashboard.php" class="navbar-brand">
            <div class="icon">🏫</div>
            <span>Smart School Web</span>
        </a>
    </header>

    <div class="container">
        <a href="dashboard.php" class="back-link">⬅️ กลับไปยัง Dashboard</a>

        <?php if (!empty($msg)): ?>
            <div class="alert alert-<?php echo $msg_type; ?>">
                <?php echo ($msg_type === 'success') ? '✅' : '⚠️'; ?> <?php echo htmlspecialchars($msg); ?>
            </div>
        <?php endif; ?>

        <!-- ฟอร์มเพิ่มวิชาใหม่ -->
        <div class="card">
            <div class="card-header">
                <h2>➕ เพิ่มรายวิชาใหม่</h2>
            </div>
            <form method="POST" action="">
                <div class="form-grid">
                    <div class="form-group">
                        <label for="subject_id">Subject ID อ้างอิง</label>
                        <input type="text" id="subject_id" name="subject_id" placeholder="เช่น SUB004" required>
                    </div>
                    <div class="form-group">
                        <label for="subject_code">รหัสวิชา</label>
                        <input type="text" id="subject_code" name="subject_code" placeholder="เช่น ว21102" required>
                    </div>
                    <div class="form-group">
                        <label for="subject_name">ชื่อรายวิชา</label>
                        <input type="text" id="subject_name" name="subject_name" placeholder="เช่น วิทยาศาสตร์ 2" required>
                    </div>
                    <div class="form-group">
                        <label for="credit">หน่วยกิต</label>
                        <input type="number" id="credit" name="credit" step="0.5" min="0.5" placeholder="เช่น 1.5" required>
                    </div>
                    <button type="submit" name="add_subject" class="btn-submit">💾 บันทึกรายวิชาใหม่</button>
                </div>
            </form>
        </div>

        <!-- ตารางแสดงรายวิชาทั้งหมด -->
        <div class="card">
            <div class="card-header">
                <h2>📚 รายวิชาทั้งหมดในระบบ</h2>
            </div>
            <?php
            $result = $conn->query("SELECT * FROM subjects ORDER BY subject_id ASC");
            if ($result && $result->num_rows > 0):
            ?>
                <table>
                    <thead>
                        <tr>
                            <th>Subject ID</th>
                            <th>รหัสวิชา</th>
                            <th>ชื่อรายวิชา</th>
                            <th>หน่วยกิต</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php while($row = $result->fetch_assoc()): ?>
                            <tr>
                                <td><code><?php echo htmlspecialchars($row['subject_id']); ?></code></td>
                                <td><span class="badge-code"><?php echo htmlspecialchars($row['subject_code']); ?></span></td>
                                <td><strong><?php echo htmlspecialchars($row['subject_name']); ?></strong></td>
                                <td><?php echo number_format($row['credit'], 1); ?> หน่วยกิต</td>
                            </tr>
                        <?php endwhile; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="empty-state">
                    <div class="icon">📭</div>
                    <p>ยังไม่มีข้อมูลรายวิชาในระบบ</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>
