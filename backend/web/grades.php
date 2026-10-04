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

// จัดการการบันทึกเกรด
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['save_grade'])) {
    $student_id = trim($_POST['student_id'] ?? '');
    $subject_id = trim($_POST['subject_id'] ?? '');
    $academic_year = trim($_POST['academic_year'] ?? '2569');
    $semester = trim($_POST['semester'] ?? '1');
    $total_score_raw = $_POST['total_score'] ?? '';

    if ($student_id === '' || $subject_id === '' || $academic_year === '' || $semester === '' || $total_score_raw === '') {
        $_SESSION['msg'] = "กรุณากรอกข้อมูลให้ครบถ้วนทุกช่อง";
        $_SESSION['msg_type'] = "error";
    } else {
        $total_score = floatval($total_score_raw);
        if ($total_score < 0 || $total_score > 100) {
            $_SESSION['msg'] = "คะแนนดิบต้องอยู่ระหว่าง 0 ถึง 100 คะแนน";
            $_SESSION['msg_type'] = "error";
        } else {
            // ระบบตัดเกรดอิงเกณฑ์มาตรฐาน
            $grade_result = 0.0;
            if ($total_score >= 80) $grade_result = 4.0;
            elseif ($total_score >= 75) $grade_result = 3.5;
            elseif ($total_score >= 70) $grade_result = 3.0;
            elseif ($total_score >= 65) $grade_result = 2.5;
            elseif ($total_score >= 60) $grade_result = 2.0;
            elseif ($total_score >= 55) $grade_result = 1.5;
            elseif ($total_score >= 50) $grade_result = 1.0;
            else $grade_result = 0.0;

            // เช็คว่าเคยมีรายการบันทึกเกรดของนักเรียน + วิชา + ปี + ภาคเรียนนี้แล้วหรือไม่ (เพื่ออัปเดตหรือแจ้งเตือน)
            $check_stmt = $conn->prepare("SELECT grade_id FROM grades WHERE student_id = ? AND subject_id = ? AND academic_year = ? AND semester = ?");
            $check_stmt->bind_param("ssss", $student_id, $subject_id, $academic_year, $semester);
            $check_stmt->execute();
            $existing = $check_stmt->get_result()->fetch_assoc();

            if ($existing) {
                // อัปเดตรายการเดิม
                $update_stmt = $conn->prepare("UPDATE grades SET total_score = ?, grade_result = ? WHERE grade_id = ?");
                $update_stmt->bind_param("ddi", $total_score, $grade_result, $existing['grade_id']);
                if ($update_stmt->execute()) {
                    $_SESSION['msg'] = "อัปเดตคะแนนเรียบร้อยแล้ว! (นักเรียน: $student_id | คะแนน: $total_score | เกรด: $grade_result)";
                    $_SESSION['msg_type'] = "success";
                } else {
                    $_SESSION['msg'] = "เกิดข้อผิดพลาดในการอัปเดต: " . $update_stmt->error;
                    $_SESSION['msg_type'] = "error";
                }
            } else {
                // บันทึกรายการใหม่
                $stmt = $conn->prepare("INSERT INTO grades (student_id, subject_id, academic_year, semester, total_score, grade_result) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt->bind_param("ssssdd", $student_id, $subject_id, $academic_year, $semester, $total_score, $grade_result);
                if ($stmt->execute()) {
                    $_SESSION['msg'] = "บันทึกคะแนนและตัดเกรดเรียบร้อยแล้ว! (เกรดที่ได้: $grade_result)";
                    $_SESSION['msg_type'] = "success";
                } else {
                    $_SESSION['msg'] = "เกิดข้อผิดพลาดในการบันทึก: " . $stmt->error;
                    $_SESSION['msg_type'] = "error";
                }
            }
        }
    }
    header("Location: grades.php");
    exit();
}

// ดึงรายชื่อนักเรียนและรายวิชามาสร้าง Dropdown
$students_option = [];
$stu_res = $conn->query("SELECT student_id, name, room FROM students ORDER BY student_id ASC");
if ($stu_res) {
    while ($row = $stu_res->fetch_assoc()) {
        $students_option[] = $row;
    }
}

$subjects_option = [];
$sub_res = $conn->query("SELECT subject_id, subject_code, subject_name FROM subjects ORDER BY subject_id ASC");
if ($sub_res) {
    while ($row = $sub_res->fetch_assoc()) {
        $subjects_option[] = $row;
    }
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>บันทึกคะแนนและตัดเกรด - Smart School Web Portal</title>
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

        .container { max-width: 1050px; margin: 32px auto; padding: 0 20px; }
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

        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; }
        .form-group { text-align: left; }
        label { display: block; font-size: 14px; font-weight: 600; color: #334155; margin-bottom: 6px; }
        input[type="text"], input[type="number"], select {
            width: 100%;
            padding: 11px 14px;
            font-size: 14.5px;
            border: 1.5px solid #cbd5e1;
            border-radius: 8px;
            outline: none;
            background: #f8fafc;
            transition: all 0.2s;
        }
        input[type="text"]:focus, input[type="number"]:focus, select:focus {
            border-color: #2563eb;
            background: #ffffff;
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
        }
        .btn-submit {
            grid-column: 1 / -1;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: white;
            border: none;
            padding: 13px 24px;
            font-size: 15.5px;
            font-weight: 600;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s;
            margin-top: 10px;
        }
        .btn-submit:hover { opacity: 0.95; transform: translateY(-1px); }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid #e2e8f0; font-size: 14.5px; }
        th { background-color: #f8fafc; font-weight: 600; color: #475569; }
        tr:hover { background-color: #f8fafc; }
        
        .grade-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-weight: 700;
            font-size: 14px;
            display: inline-block;
        }
        .grade-4 { background: #dcfce7; color: #15803d; }
        .grade-3 { background: #dbeafe; color: #1d4ed8; }
        .grade-2 { background: #fef9c3; color: #a16207; }
        .grade-1 { background: #ffedd5; color: #c2410c; }
        .grade-0 { background: #fee2e2; color: #b91c1c; }

        .empty-state { text-align: center; padding: 48px 20px; color: #94a3b8; }
        .empty-state .icon { font-size: 44px; margin-bottom: 10px; }
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

        <!-- ฟอร์มบันทึกคะแนนและตัดเกรด -->
        <div class="card">
            <div class="card-header">
                <h2>📝 บันทึกคะแนนและตัดเกรด</h2>
            </div>
            <form method="POST" action="">
                <div class="form-grid">
                    <div class="form-group">
                        <label for="student_id">เลือกรหัสนักเรียน</label>
                        <select id="student_id" name="student_id" required>
                            <option value="">-- เลือกรหัสนักเรียน --</option>
                            <?php foreach ($students_option as $st): ?>
                                <option value="<?php echo htmlspecialchars($st['student_id']); ?>">
                                    <?php echo htmlspecialchars($st['student_id'] . ' - ' . $st['name'] . ($st['room'] ? ' (' . $st['room'] . ')' : '')); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="subject_id">เลือกรายวิชา</label>
                        <select id="subject_id" name="subject_id" required>
                            <option value="">-- เลือกรายวิชา --</option>
                            <?php foreach ($subjects_option as $sub): ?>
                                <option value="<?php echo htmlspecialchars($sub['subject_id']); ?>">
                                    <?php echo htmlspecialchars($sub['subject_id'] . ' - ' . $sub['subject_code'] . ' ' . $sub['subject_name']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="academic_year">ปีการศึกษา</label>
                        <input type="text" id="academic_year" name="academic_year" value="2569" placeholder="เช่น 2569" required>
                    </div>

                    <div class="form-group">
                        <label for="semester">ภาคเรียน</label>
                        <select id="semester" name="semester" required>
                            <option value="1" selected>ภาคเรียนที่ 1</option>
                            <option value="2">ภาคเรียนที่ 2</option>
                        </select>
                    </div>

                    <div class="form-group" style="grid-column: 1 / -1;">
                        <label for="total_score">คะแนนดิบรวม (0 - 100 คะแนน)</label>
                        <input type="number" id="total_score" name="total_score" step="0.1" min="0" max="100" placeholder="กรอกคะแนนดิบ เช่น 85.5" required>
                    </div>

                    <button type="submit" name="save_grade" class="btn-submit">💾 บันทึกคะแนนและตัดเกรดอัตโนมัติ</button>
                </div>
            </form>
        </div>

        <!-- ตารางแสดงประวัติคะแนนและเกรดที่บันทึกล่าสุด -->
        <div class="card">
            <div class="card-header">
                <h2>📊 ข้อมูลคะแนนและเกรดที่บันทึกล่าสุด</h2>
            </div>
            <?php
            $sql = "SELECT g.*, 
                           s.name AS student_name, s.room AS student_room,
                           sub.subject_code, sub.subject_name
                    FROM grades g
                    LEFT JOIN students s ON g.student_id = s.student_id
                    LEFT JOIN subjects sub ON g.subject_id = sub.subject_id
                    ORDER BY g.grade_id DESC";
            $result = $conn->query($sql);
            if ($result && $result->num_rows > 0):
            ?>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>นักเรียน</th>
                            <th>รายวิชา</th>
                            <th>ปี / ภาค</th>
                            <th>คะแนนรวม</th>
                            <th>เกรดที่ได้</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php while($row = $result->fetch_assoc()): 
                            $g = floatval($row['grade_result']);
                            $badge_class = 'grade-0';
                            if ($g >= 3.5) { $badge_class = 'grade-4'; }
                            elseif ($g >= 2.5) { $badge_class = 'grade-3'; }
                            elseif ($g >= 1.5) { $badge_class = 'grade-2'; }
                            elseif ($g >= 1.0) { $badge_class = 'grade-1'; }
                        ?>
                            <tr>
                                <td><code>#<?php echo htmlspecialchars($row['grade_id']); ?></code></td>
                                <td>
                                    <strong><?php echo htmlspecialchars($row['student_name'] ?? $row['student_id']); ?></strong>
                                    <br><small style="color:#64748b;"><?php echo htmlspecialchars($row['student_id']); ?> <?php echo htmlspecialchars($row['student_room'] ?? ''); ?></small>
                                </td>
                                <td>
                                    <strong><?php echo htmlspecialchars($row['subject_name'] ?? $row['subject_id']); ?></strong>
                                    <br><small style="color:#64748b;"><?php echo htmlspecialchars($row['subject_code'] ?? $row['subject_id']); ?></small>
                                </td>
                                <td><?php echo htmlspecialchars($row['academic_year']); ?>/<?php echo htmlspecialchars($row['semester']); ?></td>
                                <td><strong><?php echo number_format($row['total_score'], 1); ?></strong></td>
                                <td>
                                    <span class="grade-badge <?php echo $badge_class; ?>">
                                        <?php echo number_format($row['grade_result'], 1); ?>
                                    </span>
                                </td>
                            </tr>
                        <?php endwhile; ?>
                    </tbody>
                </table>
            <?php else: ?>
                <div class="empty-state">
                    <div class="icon">📝</div>
                    <p>ยังไม่มีข้อมูลคะแนนที่บันทึกในระบบ</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
</body>
</html>
