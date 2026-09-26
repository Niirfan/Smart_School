<?php
/**
 * ตรวจ attendance แบบ 2 ช่วงเวลา
 * morning: ตรวจคนที่ไม่มีสแกนเข้า (ควรรันตอนเที่ยง)
 * evening: ตรวจคนที่ไม่มีสแกนออก (ควรรันหลังเวลาเลิกเรียน)
 * ส่ง phase ผ่าน ?phase=morning|evening หรือ argument ตัวที่ 2 เมื่อรัน CLI
 */
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

date_default_timezone_set('Asia/Bangkok');
include_once __DIR__ . '/db.php';

try {
    $date = isset($_GET['date']) ? trim($_GET['date']) : (isset($argv[1]) ? trim($argv[1]) : date('Y-m-d'));
    $phase = strtolower(trim($_GET['phase'] ?? ($argv[2] ?? 'morning')));

    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
        throw new Exception('รูปแบบวันที่ไม่ถูกต้อง');
    }
    if (!in_array($phase, ['morning', 'evening'], true)) {
        throw new Exception('phase ต้องเป็น morning หรือ evening');
    }

    $students_res = $conn->query('SELECT student_id, name, room FROM students ORDER BY room ASC, class_no ASC');
    if (!$students_res) {
        throw new Exception('ไม่สามารถดึงรายชื่อนักเรียนได้: ' . $conn->error);
    }

    $stmt_att = $conn->prepare(
        'SELECT daily_status, scan_in_time, scan_out_time
         FROM daily_attendance WHERE student_id = ? AND date = ?'
    );
    $stmt_leave = $conn->prepare(
        'SELECT leave_type FROM leave_requests WHERE student_id = ? AND leave_date = ?'
    );
    $stmt_insert_att = $conn->prepare(
        "INSERT INTO daily_attendance
         (attendance_id, student_id, scanned_by_teacher_id, date, scan_in_time, scan_out_time, daily_status)
         VALUES (?, ?, 'SYSTEM', ?, NULL, NULL, ?)
         ON DUPLICATE KEY UPDATE daily_status = VALUES(daily_status)"
    );
    $stmt_behavior_exists = $conn->prepare(
        'SELECT 1 FROM behaviors WHERE student_id = ? AND reason = ? LIMIT 1'
    );
    $stmt_insert_beh = $conn->prepare(
        "INSERT INTO behaviors (behavior_id, student_id, teacher_id, score_change, reason)
         VALUES (?, ?, 'SYSTEM', -3.00, ?)"
    );

    $conn->begin_transaction();
    $already_recorded_count = 0;
    $on_leave_count = 0;
    $changed = [];
    $absent_status = 'ขาด';

    while ($st = $students_res->fetch_assoc()) {
        $sid = $st['student_id'];

        $stmt_att->bind_param('ss', $sid, $date);
        $stmt_att->execute();
        $attendance = $stmt_att->get_result()->fetch_assoc();

        $stmt_leave->bind_param('ss', $sid, $date);
        $stmt_leave->execute();
        if ($stmt_leave->get_result()->num_rows > 0) {
            $on_leave_count++;
            continue;
        }

        $reason = null;
        if ($phase === 'morning') {
            // มีสแกนเข้าแล้ว ให้รอตรวจสแกนออกช่วงเย็น
            if ($attendance) {
                $already_recorded_count++;
                continue;
            }
            $reason = "ขาดเรียนโดยไม่แจ้งลา ($date)";
            $att_id = 'ATT' . date('YmdHis') . rand(1000, 9999);
            $stmt_insert_att->bind_param('ssss', $att_id, $sid, $date, $absent_status);
            $stmt_insert_att->execute();
        } else {
            // ช่วงเย็น: มีสแกนเข้าแต่ไม่มีสแกนออก ให้หัก 3 คะแนน
            if ($attendance && !empty($attendance['scan_out_time'])) {
                $already_recorded_count++;
                continue;
            }
            $reason = $attendance
                ? "ไม่สแกนออกจากโรงเรียน ($date)"
                : "ขาดเรียนโดยไม่แจ้งลา ($date)";
            if (!$attendance) {
                $att_id = 'ATT' . date('YmdHis') . rand(1000, 9999);
                $stmt_insert_att->bind_param('ssss', $att_id, $sid, $date, $absent_status);
                $stmt_insert_att->execute();
            }
        }

        // ป้องกัน Cron รันซ้ำแล้วหักคะแนนซ้ำ
        $stmt_behavior_exists->bind_param('ss', $sid, $reason);
        $stmt_behavior_exists->execute();
        if ($stmt_behavior_exists->get_result()->num_rows === 0) {
            $beh_id = 'BEH' . date('YmdHis') . rand(1000, 9999);
            $stmt_insert_beh->bind_param('sss', $beh_id, $sid, $reason);
            $stmt_insert_beh->execute();
            $changed[] = [
                'student_id' => $sid,
                'name' => $st['name'],
                'room' => $st['room'],
                'reason' => $reason,
            ];
        }
    }

    $conn->commit();
    echo json_encode([
        'success' => true,
        'date' => $date,
        'phase' => $phase,
        'already_recorded_count' => $already_recorded_count,
        'on_leave_count' => $on_leave_count,
        'changed_count' => count($changed),
        'changed_students' => $changed,
    ], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
} catch (Throwable $e) {
    if (isset($conn) && $conn->connect_errno === 0) {
        $conn->rollback();
    }
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
