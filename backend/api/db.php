<?php
date_default_timezone_set('Asia/Bangkok');

register_shutdown_function(static function (): void {
    $error = error_get_last();
    if ($error === null || !in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) {
        return;
    }
    if (!headers_sent()) {
        http_response_code(500);
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode([
        'success' => false,
        'message' => 'PHP fatal error',
        'error' => $error['message'],
        'file' => basename($error['file']),
        'line' => $error['line'],
    ], JSON_UNESCAPED_UNICODE);
});

if (!class_exists('SmartSchoolDbResult')) {
    class SmartSchoolDbResult
    {
        private array $rows;
        private int $cursor = 0;
        public int $num_rows;

        public function __construct(array $rows) { $this->rows = $rows; $this->num_rows = count($rows); }
        public function fetch_assoc(): ?array
        {
            return $this->cursor < $this->num_rows ? $this->rows[$this->cursor++] : null;
        }
    }
}

function smart_school_get_result(mysqli_stmt $stmt): SmartSchoolDbResult
{
    if (method_exists($stmt, 'get_result')) {
        $result = $stmt->get_result();
        $rows = [];
        while ($row = $result->fetch_assoc()) { $rows[] = $row; }
        return new SmartSchoolDbResult($rows);
    }
    $metadata = $stmt->result_metadata();
    if (!$metadata) return new SmartSchoolDbResult([]);
    $fields = $metadata->fetch_fields();
    $values = array_fill(0, count($fields), null);
    $refs = [];
    foreach ($values as $i => &$value) { $refs[$i] =& $value; }
    $stmt->bind_result(...$refs);
    $rows = [];
    while ($stmt->fetch()) {
        $row = [];
        foreach ($fields as $i => $field) { $row[$field->name] = $values[$i]; }
        $rows[] = $row;
    }
    return new SmartSchoolDbResult($rows);
}

// ปิดการ throw exception อัตโนมัติใน PHP 8.1+ ป้องกัน HTTP ERROR 500
mysqli_report(MYSQLI_REPORT_OFF);

$user = "6620310131"; 
$pass = "6620310131"; 
$dbname = "6620310131_smartschool_db";

// รายการ host ที่จะทดสอบเชื่อมต่อตามลำดับ
$hosts = ['172.18.111.42', 'localhost', '127.0.0.1'];

$conn = null;
$last_error = '';

foreach ($hosts as $h) {
    try {
        $c = @new mysqli($h, $user, $pass, $dbname);
        if ($c && !$c->connect_error) {
            $conn = $c;
            break;
        } else {
            if ($c) { $last_error = $c->connect_error; }
        }
    } catch (Throwable $e) {
        $last_error = $e->getMessage();
    }
}

if (!$conn || $conn->connect_error) {
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'เชื่อมต่อฐานข้อมูลไม่สำเร็จ: ' . ($last_error !== '' ? $last_error : 'Connection failed')
    ], JSON_UNESCAPED_UNICODE);
    exit();
}

$conn->set_charset("utf8mb4");
?>
