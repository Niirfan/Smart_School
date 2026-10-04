<?php
require_once __DIR__ . '/session.php';
include 'db.php';

if (!isset($_SESSION['teacher_id'])) {
    header("Location: index.php");
    exit();
}

$teacher_name = $_SESSION['teacher_name'] ?? 'คุณครู';
$teacher_id = $_SESSION['teacher_id'] ?? '';

// ดึงสถิติต่างๆ
$count_subjects = 0;
$count_students = 0;
$count_grades = 0;

$res_sub = $conn->query("SELECT COUNT(*) AS total FROM subjects");
if ($res_sub) { $count_subjects = $res_sub->fetch_assoc()['total']; }

$res_stu = $conn->query("SELECT COUNT(*) AS total FROM students");
if ($res_stu) { $count_students = $res_stu->fetch_assoc()['total']; }

$res_grd = $conn->query("SELECT COUNT(*) AS total FROM grades");
if ($res_grd) { $count_grades = $res_grd->fetch_assoc()['total']; }
?>
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - Smart School Web Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Sarabun', sans-serif; }
        body { background-color: #f1f5f9; color: #1e293b; min-height: 100vh; }
        .navbar {
            background: #ffffff;
            border-bottom: 1px solid #e2e8f0;
            padding: 16px 32px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .navbar-brand { display: flex; align-items: center; gap: 12px; font-weight: 700; font-size: 20px; color: #0f172a; }
        .navbar-brand .icon { background: #2563eb; color: white; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 20px; }
        .user-info { display: flex; align-items: center; gap: 16px; }
        .user-badge { background: #eff6ff; color: #1d4ed8; padding: 6px 14px; border-radius: 20px; font-size: 14px; font-weight: 600; }
        .btn-logout { background: #fee2e2; color: #991b1b; text-decoration: none; padding: 8px 16px; border-radius: 8px; font-weight: 600; font-size: 14px; transition: all 0.2s; }
        .btn-logout:hover { background: #fca5a5; }

        .container { max-width: 1100px; margin: 40px auto; padding: 0 20px; }
        .welcome-card {
            background: linear-gradient(135deg, #1e293b, #0f172a);
            color: white;
            padding: 32px;
            border-radius: 18px;
            margin-bottom: 32px;
            box-shadow: 0 10px 25px rgba(15, 23, 42, 0.15);
        }
        .welcome-card h1 { font-size: 26px; font-weight: 700; margin-bottom: 8px; }
        .welcome-card p { opacity: 0.85; font-size: 15px; }

        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 20px; margin-bottom: 36px; }
        .stat-card {
            background: white;
            padding: 24px;
            border-radius: 16px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
            display: flex;
            align-items: center;
            gap: 20px;
        }
        .stat-icon {
            width: 56px;
            height: 56px;
            border-radius: 14px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
        }
        .icon-blue { background: #dbeafe; color: #1d4ed8; }
        .icon-green { background: #dcfce7; color: #15803d; }
        .icon-purple { background: #f3e8ff; color: #6b21a8; }
        .stat-data h3 { font-size: 26px; font-weight: 700; color: #0f172a; }
        .stat-data p { color: #64748b; font-size: 14px; margin-top: 2px; }

        .section-title { font-size: 20px; font-weight: 700; margin-bottom: 20px; color: #0f172a; }
        .menu-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px; }
        .menu-card {
            background: white;
            border-radius: 18px;
            padding: 28px;
            border: 1px solid #e2e8f0;
            box-shadow: 0 4px 12px rgba(0,0,0,0.03);
            transition: all 0.25s ease;
            text-decoration: none;
            color: inherit;
            display: block;
        }
        .menu-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 12px 24px rgba(0,0,0,0.08);
            border-color: #cbd5e1;
        }
        .menu-header { display: flex; align-items: center; gap: 16px; margin-bottom: 14px; }
        .menu-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
        .menu-card h3 { font-size: 19px; font-weight: 700; color: #0f172a; }
        .menu-card p { color: #64748b; font-size: 14px; line-height: 1.5; }
        .arrow-link { margin-top: 20px; font-weight: 600; font-size: 14px; color: #2563eb; display: inline-flex; align-items: center; gap: 6px; }
    </style>
</head>
<body>
    <header class="navbar">
        <div class="navbar-brand">
            <div class="icon">🏫</div>
            <span>Smart School Web</span>
        </div>
        <div class="user-info">
            <span class="user-badge">👤 คุณครู<?php echo htmlspecialchars($teacher_name); ?> (<?php echo htmlspecialchars($teacher_id); ?>)</span>
            <a href="logout.php" class="btn-logout">🚪 ออกจากระบบ</a>
        </div>
    </header>

    <div class="container">
        <div class="welcome-card">
            <h1>ยินดีต้อนรับ, ครู<?php echo htmlspecialchars($teacher_name); ?></h1>
            <p>ระบบบริหารจัดการวิชาและตัดเกรดออนไลน์สำหรับครูผู้สอน Smart School</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon icon-blue">📚</div>
                <div class="stat-data">
                    <h3><?php echo number_format($count_subjects); ?></h3>
                    <p>รายวิชาในระบบ</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon icon-green">👨‍🎓</div>
                <div class="stat-data">
                    <h3><?php echo number_format($count_students); ?></h3>
                    <p>นักเรียนทั้งหมด</p>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-icon icon-purple">📝</div>
                <div class="stat-data">
                    <h3><?php echo number_format($count_grades); ?></h3>
                    <p>รายการเกรดที่บันทึก</p>
                </div>
            </div>
        </div>

        <h2 class="section-title">เมนูหลักการทำงาน</h2>
        <div class="menu-grid">
            <a href="subjects.php" class="menu-card">
                <div class="menu-header">
                    <div class="menu-icon icon-blue">📚</div>
                    <h3>จัดการรายวิชา</h3>
                </div>
                <p>ดูรายการวิชาทั้งหมดในระบบ และเพิ่มรายวิชาใหม่พร้อมกำหนดหน่วยกิต</p>
                <div class="arrow-link">เข้าสู่หน้าจัดการวิชา ➔</div>
            </a>

            <a href="grades.php" class="menu-card">
                <div class="menu-header">
                    <div class="menu-icon icon-purple">📝</div>
                    <h3>บันทึกคะแนนและตัดเกรด</h3>
                </div>
                <p>เลือกนักเรียน วิชา และกรอกคะแนนตัดเกรดอัตโนมัติ พร้อมดูตารางประวัติล่าสุด</p>
                <div class="arrow-link">เข้าสู่หน้าบันทึกเกรด ➔</div>
            </a>
        </div>
    </div>
</body>
</html>
