<?php
require_once __DIR__ . '/session.php';
include 'db.php';

if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}
if (!$conn || !empty($db_error)) {
    header("Location: index.php");
    exit();
}

$teacher_id   = $_SESSION['teacher_id'];
$teacher_name = $_SESSION['teacher_name'] ?? 'ครู';
$msg      = $_SESSION['msg'] ?? '';
$msg_type = $_SESSION['msg_type'] ?? '';
unset($_SESSION['msg'], $_SESSION['msg_type']);

// ─── POST: บันทึกเกรดทั้งห้องพร้อมกัน ───────────────────
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['bulk_save'])) {
    $subject_id    = trim($_POST['subject_id'] ?? '');
    $room          = trim($_POST['room'] ?? '');
    $academic_year = trim($_POST['academic_year'] ?? '');
    $semester      = trim($_POST['semester'] ?? '');
    $scores        = $_POST['scores'] ?? [];

    // ตรวจสิทธิ์: ครูต้องสอนวิชา+ห้องนี้จริง
    $auth = $conn->prepare(
        "SELECT schedule_id FROM timetables WHERE teacher_id=? AND subject_id=? AND room=? LIMIT 1"
    );
    $auth->bind_param("sss", $teacher_id, $subject_id, $room);
    $auth->execute();
    if ($auth->get_result()->num_rows === 0) {
        $_SESSION['msg']      = "คุณไม่มีสิทธิ์ตัดเกรดวิชา/ห้องนี้";
        $_SESSION['msg_type'] = "error";
        header("Location: grades.php");
        exit();
    }

    $saved = 0; $skipped = 0; $errors = [];

    foreach ($scores as $sid => $raw) {
        $raw = trim($raw);
        if ($raw === '') { $skipped++; continue; }

        $total_score = floatval($raw);
        if ($total_score < 0 || $total_score > 100) {
            $errors[] = "คะแนน $sid ต้องอยู่ระหว่าง 0-100";
            continue;
        }

        // ตัดเกรดอิงเกณฑ์
        $grade_result = 0.0;
        if ($total_score >= 80)      $grade_result = 4.0;
        elseif ($total_score >= 75)  $grade_result = 3.5;
        elseif ($total_score >= 70)  $grade_result = 3.0;
        elseif ($total_score >= 65)  $grade_result = 2.5;
        elseif ($total_score >= 60)  $grade_result = 2.0;
        elseif ($total_score >= 55)  $grade_result = 1.5;
        elseif ($total_score >= 50)  $grade_result = 1.0;
        else                          $grade_result = 0.0;

        $chk = $conn->prepare(
            "SELECT grade_id FROM grades WHERE student_id=? AND subject_id=? AND academic_year=? AND semester=?"
        );
        $chk->bind_param("ssss", $sid, $subject_id, $academic_year, $semester);
        $chk->execute();
        $exist = $chk->get_result()->fetch_assoc();

        if ($exist) {
            $upd = $conn->prepare("UPDATE grades SET total_score=?, grade_result=? WHERE grade_id=?");
            $upd->bind_param("ddi", $total_score, $grade_result, $exist['grade_id']);
            $upd->execute() ? $saved++ : $errors[] = "อัปเดต $sid ล้มเหลว";
        } else {
            $ins = $conn->prepare(
                "INSERT INTO grades (student_id,subject_id,academic_year,semester,total_score,grade_result)
                 VALUES (?,?,?,?,?,?)"
            );
            $ins->bind_param("ssssdd", $sid, $subject_id, $academic_year, $semester, $total_score, $grade_result);
            $ins->execute() ? $saved++ : $errors[] = "บันทึก $sid ล้มเหลว";
        }
    }

    if (count($errors)) {
        $_SESSION['msg']      = "บันทึก $saved รายการ | ผิดพลาด: " . implode(', ', $errors);
        $_SESSION['msg_type'] = "error";
    } else {
        $_SESSION['msg']      = "บันทึก/อัปเดต $saved รายการเรียบร้อย (ข้ามว่าง $skipped รายการ)";
        $_SESSION['msg_type'] = "success";
    }

    header("Location: grades.php?subject_id=" . urlencode($subject_id)
        . "&room=" . urlencode($room)
        . "&academic_year=" . urlencode($academic_year)
        . "&semester=" . urlencode($semester));
    exit();
}

// ─── ดึงวิชาที่ครูสอน (จากตาราง timetables) ─────────────
$sub_stmt = $conn->prepare(
    "SELECT DISTINCT t.subject_id, s.subject_code, s.subject_name, s.credit, t.room
     FROM timetables t
     JOIN subjects s ON t.subject_id = s.subject_id
     WHERE t.teacher_id = ?
     ORDER BY s.subject_code, t.room"
);
$sub_stmt->bind_param("s", $teacher_id);
$sub_stmt->execute();
$sub_rows = $sub_stmt->get_result()->fetch_all(MYSQLI_ASSOC);

// จัดกลุ่ม: subject_id => { info, rooms[] }
$my_subjects = [];
foreach ($sub_rows as $r) {
    $sid = $r['subject_id'];
    if (!isset($my_subjects[$sid])) {
        $my_subjects[$sid] = [
            'subject_id'   => $sid,
            'subject_code' => $r['subject_code'],
            'subject_name' => $r['subject_name'],
            'credit'       => $r['credit'],
            'rooms'        => [],
        ];
    }
    $my_subjects[$sid]['rooms'][] = $r['room'];
}

// ─── Query string ─────────────────────────────────────────
$sel_sid  = trim($_GET['subject_id'] ?? '');
$sel_room = trim($_GET['room'] ?? '');
$sel_year = trim($_GET['academic_year'] ?? '2569');
$sel_sem  = trim($_GET['semester'] ?? '1');

$students_in_room = [];
$grades_map       = [];
$sub_info         = null;

if ($sel_sid !== '' && $sel_room !== '') {
    if (isset($my_subjects[$sel_sid]) && in_array($sel_room, $my_subjects[$sel_sid]['rooms'])) {
        $sub_info = $my_subjects[$sel_sid];

        // นักเรียนในห้อง เรียงตามเลขที่
        $stu = $conn->prepare(
            "SELECT student_id, name, class_no FROM students WHERE room=? ORDER BY class_no ASC"
        );
        $stu->bind_param("s", $sel_room);
        $stu->execute();
        $students_in_room = $stu->get_result()->fetch_all(MYSQLI_ASSOC);

        // เกรดที่บันทึกไว้แล้ว
        $gr = $conn->prepare(
            "SELECT student_id, total_score, grade_result FROM grades
             WHERE subject_id=? AND academic_year=? AND semester=?"
        );
        $gr->bind_param("sss", $sel_sid, $sel_year, $sel_sem);
        $gr->execute();
        foreach ($gr->get_result()->fetch_all(MYSQLI_ASSOC) as $row) {
            $grades_map[$row['student_id']] = $row;
        }
    }
}

// ─── ประวัติเกรดของครูคนนี้ ──────────────────────────────
$hist = $conn->prepare(
    "SELECT g.grade_id, g.student_id, g.subject_id, g.academic_year, g.semester,
            g.total_score, g.grade_result,
            st.name AS student_name, st.room AS student_room,
            sub.subject_code, sub.subject_name
     FROM grades g
     JOIN timetables tt ON tt.subject_id = g.subject_id
         AND tt.room = (SELECT room FROM students WHERE student_id = g.student_id LIMIT 1)
         AND tt.teacher_id = ?
     JOIN students st ON st.student_id = g.student_id
     JOIN subjects sub ON sub.subject_id = g.subject_id
     GROUP BY g.grade_id
     ORDER BY g.grade_id DESC
     LIMIT 60"
);
$hist->bind_param("s", $teacher_id);
$hist->execute();
$history_rows = $hist->get_result()->fetch_all(MYSQLI_ASSOC);

function gradeClass(float $g): string {
    if ($g >= 3.5) return 'grade-4';
    if ($g >= 2.5) return 'grade-3';
    if ($g >= 1.5) return 'grade-2';
    if ($g >= 1.0) return 'grade-1';
    return 'grade-0';
}
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ตัดเกรด – Smart School Web Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Sarabun', sans-serif; }
        body { background: #f1f5f9; color: #1e293b; min-height: 100vh; padding-bottom: 60px; }

        /* Navbar */
        .navbar { background:#fff; border-bottom:1px solid #e2e8f0; padding:14px 28px; display:flex; justify-content:space-between; align-items:center; box-shadow:0 1px 4px rgba(0,0,0,.06); position:sticky; top:0; z-index:100; }
        .navbar-brand { display:flex; align-items:center; gap:10px; font-weight:700; font-size:18px; color:#0f172a; text-decoration:none; }
        .navbar-brand .icon { background:#2563eb; color:#fff; width:36px; height:36px; border-radius:9px; display:flex; align-items:center; justify-content:center; font-size:18px; }
        .user-badge { background:#eff6ff; color:#1d4ed8; padding:5px 12px; border-radius:20px; font-size:13px; font-weight:600; }

        /* Layout */
        .container { max-width:1100px; margin:28px auto; padding:0 20px; }
        .back-link { display:inline-flex; align-items:center; gap:6px; text-decoration:none; color:#64748b; font-weight:600; margin-bottom:20px; transition:color .2s; font-size:14px; }
        .back-link:hover { color:#2563eb; }

        /* Alert */
        .alert { padding:13px 18px; border-radius:10px; font-size:14px; margin-bottom:22px; display:flex; align-items:flex-start; gap:10px; line-height:1.5; }
        .alert-success { background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; }
        .alert-error   { background:#fef2f2; border:1px solid #fecaca; color:#991b1b; }

        /* Section label */
        .section-label { font-size:13px; font-weight:700; color:#475569; text-transform:uppercase; letter-spacing:.6px; margin-bottom:14px; }

        /* Subject cards */
        .subject-grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(260px,1fr)); gap:16px; margin-bottom:30px; }
        .subject-card { background:#fff; border-radius:14px; border:1.5px solid #e2e8f0; padding:20px; box-shadow:0 2px 6px rgba(0,0,0,.04); transition:all .2s; }
        .subject-card:hover { border-color:#93c5fd; box-shadow:0 6px 16px rgba(37,99,235,.1); transform:translateY(-2px); }
        .sub-code { background:#eff6ff; color:#1d4ed8; font-weight:700; font-size:12px; padding:3px 10px; border-radius:6px; display:inline-block; margin-bottom:8px; }
        .sub-name { font-size:15px; font-weight:700; color:#0f172a; margin-bottom:4px; }
        .sub-credit { font-size:13px; color:#64748b; margin-bottom:12px; }
        .room-btns { display:flex; flex-wrap:wrap; gap:8px; }
        .btn-room { padding:7px 15px; border-radius:8px; font-size:13px; font-weight:600; text-decoration:none; background:#f1f5f9; color:#334155; border:1.5px solid #cbd5e1; transition:all .15s; }
        .btn-room:hover, .btn-room.active { background:#2563eb; color:#fff; border-color:#2563eb; }

        /* Grade panel */
        .grade-card { background:#fff; border-radius:16px; border:1px solid #e2e8f0; padding:28px; box-shadow:0 4px 12px rgba(0,0,0,.04); margin-bottom:28px; }
        .grade-card-header { display:flex; align-items:center; justify-content:space-between; padding-bottom:16px; border-bottom:1px solid #f1f5f9; margin-bottom:22px; flex-wrap:wrap; gap:12px; }
        .grade-card-header h2 { font-size:18px; font-weight:700; color:#0f172a; display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
        .badge-room { background:#dcfce7; color:#15803d; padding:4px 12px; border-radius:20px; font-size:13px; font-weight:700; }

        /* Filter bar */
        .filter-bar { display:flex; flex-wrap:wrap; gap:14px; align-items:flex-end; margin-bottom:22px; }
        .filter-bar .fg { display:flex; flex-direction:column; gap:5px; }
        .filter-bar label { font-size:13px; font-weight:600; color:#475569; }
        .filter-bar input[type="text"], .filter-bar select { padding:9px 12px; font-size:13px; border:1.5px solid #cbd5e1; border-radius:8px; background:#f8fafc; outline:none; transition:all .2s; min-width:130px; }
        .filter-bar input[type="text"]:focus, .filter-bar select:focus { border-color:#2563eb; background:#fff; box-shadow:0 0 0 3px rgba(37,99,235,.1); }
        .btn-filter { padding:9px 20px; background:#2563eb; color:#fff; border:none; border-radius:8px; font-size:14px; font-weight:600; cursor:pointer; }
        .btn-filter:hover { background:#1d4ed8; }

        /* Table */
        .table-wrap { overflow-x:auto; }
        table { width:100%; border-collapse:collapse; }
        th, td { padding:12px 16px; text-align:left; border-bottom:1px solid #f1f5f9; font-size:14px; }
        th { background:#f8fafc; font-weight:700; color:#475569; font-size:12.5px; text-transform:uppercase; letter-spacing:.3px; }
        tr:hover td { background:#fafbfe; }
        .class-no { background:#eff6ff; color:#1d4ed8; font-weight:700; font-size:12px; padding:2px 8px; border-radius:5px; }
        .score-input { width:88px; padding:8px 10px; border:1.5px solid #cbd5e1; border-radius:8px; font-size:14px; text-align:center; background:#f8fafc; outline:none; transition:all .2s; }
        .score-input:focus { border-color:#2563eb; background:#fff; box-shadow:0 0 0 3px rgba(37,99,235,.1); }

        /* Grade badge */
        .grade-badge { padding:4px 12px; border-radius:20px; font-weight:700; font-size:13px; display:inline-block; }
        .grade-4 { background:#dcfce7; color:#15803d; }
        .grade-3 { background:#dbeafe; color:#1d4ed8; }
        .grade-2 { background:#fef9c3; color:#a16207; }
        .grade-1 { background:#ffedd5; color:#c2410c; }
        .grade-0 { background:#fee2e2; color:#b91c1c; }
        .preview-span { min-width:50px; display:inline-block; }

        /* Save bar */
        .save-bar { display:flex; justify-content:flex-end; align-items:center; margin-top:20px; gap:14px; }
        .save-hint { font-size:13px; color:#94a3b8; }
        .btn-save { padding:12px 32px; background:linear-gradient(135deg,#2563eb,#1d4ed8); color:#fff; border:none; border-radius:10px; font-size:15px; font-weight:700; cursor:pointer; box-shadow:0 4px 12px rgba(37,99,235,.25); transition:all .2s; }
        .btn-save:hover { transform:translateY(-2px); box-shadow:0 6px 18px rgba(37,99,235,.35); }

        /* History */
        .history-card { background:#fff; border-radius:16px; border:1px solid #e2e8f0; padding:24px; box-shadow:0 2px 8px rgba(0,0,0,.04); }
        .history-card h2 { font-size:17px; font-weight:700; color:#0f172a; margin-bottom:16px; }

        /* Empty / No subject */
        .empty-state { text-align:center; padding:48px 20px; color:#94a3b8; }
        .empty-state .icon { font-size:44px; margin-bottom:10px; }
        .no-subject-box { background:#fffbeb; border:1.5px dashed #fbbf24; border-radius:14px; padding:36px; text-align:center; color:#92400e; margin-bottom:30px; }
        .no-subject-box .icon { font-size:42px; margin-bottom:10px; }
    </style>
</head>
<body>
<header class="navbar">
    <a href="dashboard.php" class="navbar-brand">
        <div class="icon">🏫</div>
        <span>Smart School Web</span>
    </a>
    <span class="user-badge">👤 <?php echo htmlspecialchars($teacher_name); ?></span>
</header>

<div class="container">
    <a href="dashboard.php" class="back-link">⬅️ กลับ Dashboard</a>

    <?php if (!empty($msg)): ?>
        <div class="alert alert-<?php echo htmlspecialchars($msg_type); ?>">
            <?php echo ($msg_type === 'success') ? '✅' : '⚠️'; ?>
            <?php echo htmlspecialchars($msg); ?>
        </div>
    <?php endif; ?>

    <!-- วิชาที่ครูสอน -->
    <div class="section-label">📚 วิชาที่คุณสอน – เลือกวิชาและห้องเพื่อตัดเกรด</div>

    <?php if (empty($my_subjects)): ?>
        <div class="no-subject-box">
            <div class="icon">📭</div>
            <p style="font-weight:700;font-size:16px;margin-bottom:6px;">ไม่พบรายวิชาที่คุณสอนในระบบ</p>
            <p style="font-size:14px;">กรุณาติดต่อผู้ดูแลระบบเพื่อเพิ่มตารางสอน</p>
        </div>
    <?php else: ?>
        <div class="subject-grid">
            <?php foreach ($my_subjects as $sub): ?>
                <div class="subject-card">
                    <span class="sub-code"><?php echo htmlspecialchars($sub['subject_code']); ?></span>
                    <div class="sub-name"><?php echo htmlspecialchars($sub['subject_name']); ?></div>
                    <div class="sub-credit"><?php echo number_format($sub['credit'], 1); ?> หน่วยกิต</div>
                    <div class="room-btns">
                        <?php foreach ($sub['rooms'] as $rm):
                            $active = ($sel_sid === $sub['subject_id'] && $sel_room === $rm) ? 'active' : '';
                            $url = "grades.php?subject_id=" . urlencode($sub['subject_id'])
                                 . "&room=" . urlencode($rm)
                                 . "&academic_year=" . urlencode($sel_year)
                                 . "&semester=" . urlencode($sel_sem);
                        ?>
                            <a href="<?php echo $url; ?>" class="btn-room <?php echo $active; ?>">
                                🏫 <?php echo htmlspecialchars($rm); ?>
                            </a>
                        <?php endforeach; ?>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>

    <!-- ฟอร์มตัดเกรดรายห้อง -->
    <?php if ($sub_info && !empty($students_in_room)): ?>
        <div class="grade-card">
            <div class="grade-card-header">
                <h2>
                    📝 ตัดเกรด –
                    <?php echo htmlspecialchars($sub_info['subject_code'] . ' ' . $sub_info['subject_name']); ?>
                    <span class="badge-room">🏫 <?php echo htmlspecialchars($sel_room); ?></span>
                </h2>
                <span style="font-size:13px;color:#64748b;">
                    นักเรียน <?php echo count($students_in_room); ?> คน
                </span>
            </div>

            <!-- เลือกปีการศึกษา / ภาคเรียน -->
            <form method="GET" action="">
                <input type="hidden" name="subject_id" value="<?php echo htmlspecialchars($sel_sid); ?>">
                <input type="hidden" name="room"       value="<?php echo htmlspecialchars($sel_room); ?>">
                <div class="filter-bar">
                    <div class="fg">
                        <label>ปีการศึกษา</label>
                        <input type="text" name="academic_year"
                               value="<?php echo htmlspecialchars($sel_year); ?>"
                               placeholder="เช่น 2569">
                    </div>
                    <div class="fg">
                        <label>ภาคเรียน</label>
                        <select name="semester">
                            <option value="1" <?php echo $sel_sem=='1'?'selected':''; ?>>ภาคเรียนที่ 1</option>
                            <option value="2" <?php echo $sel_sem=='2'?'selected':''; ?>>ภาคเรียนที่ 2</option>
                        </select>
                    </div>
                    <button type="submit" class="btn-filter">🔍 โหลดคะแนน</button>
                </div>
            </form>

            <!-- ตารางกรอกคะแนน -->
            <form method="POST" action="">
                <input type="hidden" name="bulk_save"     value="1">
                <input type="hidden" name="subject_id"    value="<?php echo htmlspecialchars($sel_sid); ?>">
                <input type="hidden" name="room"          value="<?php echo htmlspecialchars($sel_room); ?>">
                <input type="hidden" name="academic_year" value="<?php echo htmlspecialchars($sel_year); ?>">
                <input type="hidden" name="semester"      value="<?php echo htmlspecialchars($sel_sem); ?>">

                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th style="width:50px;">เลขที่</th>
                                <th>ชื่อ-นามสกุล</th>
                                <th>รหัสนักเรียน</th>
                                <th style="width:110px;">คะแนน (0-100)</th>
                                <th style="width:90px;">เกรด</th>
                                <th style="width:100px;">สถานะ</th>
                            </tr>
                        </thead>
                        <tbody>
                        <?php foreach ($students_in_room as $stu):
                            $sid      = $stu['student_id'];
                            $gr_exist = $grades_map[$sid] ?? null;
                            $cur_score = $gr_exist ? number_format(floatval($gr_exist['total_score']), 1) : '';
                            $cur_grade = $gr_exist ? floatval($gr_exist['grade_result']) : null;
                            $safe_sid  = htmlspecialchars($sid);
                        ?>
                            <tr>
                                <td><span class="class-no"><?php echo htmlspecialchars($stu['class_no']); ?></span></td>
                                <td><strong><?php echo htmlspecialchars($stu['name']); ?></strong></td>
                                <td style="color:#64748b;font-size:13px;"><?php echo $safe_sid; ?></td>
                                <td>
                                    <input type="number"
                                           name="scores[<?php echo $safe_sid; ?>]"
                                           class="score-input"
                                           min="0" max="100" step="0.5"
                                           value="<?php echo htmlspecialchars($cur_score); ?>"
                                           placeholder="–"
                                           oninput="previewGrade(this,'<?php echo $safe_sid; ?>')">
                                </td>
                                <td>
                                    <span id="pg_<?php echo $safe_sid; ?>" class="preview-span">
                                    <?php if ($cur_grade !== null): ?>
                                        <span class="grade-badge <?php echo gradeClass($cur_grade); ?>">
                                            <?php echo number_format($cur_grade, 1); ?>
                                        </span>
                                    <?php else: ?>–<?php endif; ?>
                                    </span>
                                </td>
                                <td style="font-size:13px;">
                                    <?php if ($gr_exist): ?>
                                        <span style="color:#15803d;font-weight:600;">✅ มีเกรดแล้ว</span>
                                    <?php else: ?>
                                        <span style="color:#94a3b8;">ยังไม่มี</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>

                <div class="save-bar">
                    <span class="save-hint">💡 เว้นช่องว่างเพื่อข้ามนักเรียนคนนั้น</span>
                    <button type="submit" class="btn-save">💾 บันทึกคะแนนทั้งหมด</button>
                </div>
            </form>
        </div>

    <?php elseif ($sel_sid !== '' && $sel_room !== ''): ?>
        <div class="grade-card">
            <div class="empty-state">
                <div class="icon">👤</div>
                <p>ไม่พบนักเรียนในห้อง <strong><?php echo htmlspecialchars($sel_room); ?></strong></p>
            </div>
        </div>
    <?php endif; ?>

    <!-- ประวัติเกรดของครูคนนี้ -->
    <div class="history-card">
        <h2>📊 ประวัติเกรดของวิชาที่คุณสอน (60 รายการล่าสุด)</h2>
        <?php if (!empty($history_rows)): ?>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>นักเรียน</th>
                            <th>ห้อง</th>
                            <th>วิชา</th>
                            <th>ปี/ภาค</th>
                            <th>คะแนน</th>
                            <th>เกรด</th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php foreach ($history_rows as $row):
                        $g = floatval($row['grade_result']);
                    ?>
                        <tr>
                            <td>
                                <strong><?php echo htmlspecialchars($row['student_name'] ?? $row['student_id']); ?></strong>
                                <br><small style="color:#94a3b8;"><?php echo htmlspecialchars($row['student_id']); ?></small>
                            </td>
                            <td>
                                <span class="badge-room" style="font-size:12px;padding:3px 10px;">
                                    <?php echo htmlspecialchars($row['student_room'] ?? '–'); ?>
                                </span>
                            </td>
                            <td>
                                <strong><?php echo htmlspecialchars($row['subject_name']); ?></strong>
                                <br><small style="color:#94a3b8;"><?php echo htmlspecialchars($row['subject_code']); ?></small>
                            </td>
                            <td><?php echo htmlspecialchars($row['academic_year']); ?>/<?php echo htmlspecialchars($row['semester']); ?></td>
                            <td><strong><?php echo number_format(floatval($row['total_score']), 1); ?></strong></td>
                            <td>
                                <span class="grade-badge <?php echo gradeClass($g); ?>">
                                    <?php echo number_format($g, 1); ?>
                                </span>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php else: ?>
            <div class="empty-state">
                <div class="icon">📝</div>
                <p>ยังไม่มีข้อมูลเกรดในวิชาที่คุณสอน</p>
            </div>
        <?php endif; ?>
    </div>
</div>

<script>
// Preview เกรด real-time ขณะพิมพ์คะแนน
function previewGrade(input, sid) {
    var el = document.getElementById('pg_' + sid);
    var v  = parseFloat(input.value);
    if (isNaN(v) || input.value.trim() === '') { el.innerHTML = '–'; return; }
    var g = 0, cls = 'grade-0';
    if      (v >= 80) { g = 4.0; cls = 'grade-4'; }
    else if (v >= 75) { g = 3.5; cls = 'grade-4'; }
    else if (v >= 70) { g = 3.0; cls = 'grade-3'; }
    else if (v >= 65) { g = 2.5; cls = 'grade-3'; }
    else if (v >= 60) { g = 2.0; cls = 'grade-2'; }
    else if (v >= 55) { g = 1.5; cls = 'grade-2'; }
    else if (v >= 50) { g = 1.0; cls = 'grade-1'; }
    else              { g = 0.0; cls = 'grade-0'; }
    el.innerHTML = '<span class="grade-badge ' + cls + '">' + g.toFixed(1) + '</span>';
}
</script>
</body>
</html>
