<?php
/**
 * session.php - การจัดการ Session สำหรับระบบเว็บครู
 */
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
