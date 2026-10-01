-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 172.18.111.42:3306
-- Generation Time: Oct 01, 2026 at 06:34 AM
-- Server version: 10.11.14-MariaDB-0ubuntu0.24.04.1
-- PHP Version: 8.3.35

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `6620310131_smartschool_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `behaviors`
--

CREATE TABLE `behaviors` (
  `behavior_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `teacher_id` varchar(50) NOT NULL,
  `score_change` decimal(6,2) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `behaviors`
--

INSERT INTO `behaviors` (`behavior_id`, `student_id`, `teacher_id`, `score_change`, `reason`, `created_at`) VALUES
('BEH001', 'S001', 'T003', 5.00, 'ช่วยเหลือเพื่อนในห้องเรียน', '2026-09-05 03:20:00'),
('BEH002', 'S003', 'T003', -5.00, 'มาสายซ้ำเกิน 3 ครั้งในเดือน', '2026-09-06 01:15:00'),
('BEH003', 'S002', 'T001', 3.00, 'ตั้งใจทำการบ้านส่งครบทุกครั้ง', '2026-09-07 06:00:00'),
('BEH101', 'S008', 'T003', -3.00, 'ไม่ทำการบ้านติดต่อกัน 3 ครั้ง', '2026-09-20 02:00:00'),
('BEH102', 'S011', 'T003', 5.00, 'เป็นตัวแทนช่วยงานกิจกรรมโรงเรียน', '2026-09-21 03:00:00'),
('BEH103', 'S013', 'T004', -10.00, 'หนีเรียนไม่แจ้งล่วงหน้า', '2026-09-24 04:00:00'),
('BEH104', 'S018', 'T005', -5.00, 'ทะเลาะวิวาทกับเพื่อนในห้องเรียน', '2026-09-22 06:00:00'),
('BEH105', 'S015', 'T003', 10.00, 'ได้รับรางวัลเรียนดีระดับโรงเรียน', '2026-09-19 01:30:00'),
('BEH106', 'S020', 'T005', -15.00, 'ขาดเรียนสะสมเกินเกณฑ์ที่กำหนด', '2026-09-25 07:00:00'),
('BEH20260923180652585', 'S001', 'T003', -5.00, 'ผมยาว', '2026-09-23 11:06:53'),
('BEH20260923182630459', 'S001', 'T003', -3.00, 'ออกนอกบริเวณโรงเรียนโดยไม่ได้รับอนุญาต', '2026-09-23 11:26:29'),
('BEH20260924143435366', 'S001', 'T001', -1.50, 'มาสาย 15 นาที (เข้าโรงเรียนเวลา 08:15:00)', '2026-09-24 07:34:35'),
('BEH20260926232817962', 'S001', 'T003', 10.00, 'ทำความสะอาดมัสยิด', '2026-09-26 16:28:17');

-- --------------------------------------------------------

--
-- Table structure for table `daily_attendance`
--

CREATE TABLE `daily_attendance` (
  `attendance_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `scanned_by_teacher_id` varchar(50) DEFAULT NULL,
  `date` date NOT NULL,
  `scan_in_time` time DEFAULT NULL,
  `scan_out_time` time DEFAULT NULL,
  `daily_status` enum('มาเรียน','มาสาย','ลาป่วย','ลากิจ','ขาด') DEFAULT 'มาเรียน'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `daily_attendance`
--

INSERT INTO `daily_attendance` (`attendance_id`, `student_id`, `scanned_by_teacher_id`, `date`, `scan_in_time`, `scan_out_time`, `daily_status`) VALUES
('ATT001', 'S001', 'T001', '2026-09-08', '07:45:00', '16:00:00', 'มาเรียน'),
('ATT002', 'S002', 'T001', '2026-09-08', '08:10:00', '16:00:00', 'มาสาย'),
('ATT003', 'S003', 'T001', '2026-09-08', NULL, NULL, 'ขาด'),
('ATT004', 'S004', 'T001', '2026-09-08', '07:50:00', '16:00:00', 'มาเรียน'),
('ATT005', 'S005', 'T001', '2026-09-08', NULL, NULL, 'ลากิจ'),
('ATT006', 'S001', 'T001', '2026-09-09', '07:40:00', '16:00:00', 'มาเรียน'),
('ATT007', 'S002', 'T001', '2026-09-09', '07:48:00', '16:00:00', 'มาเรียน'),
('ATT101', 'S001', 'T001', '2026-09-25', '07:42:00', '16:00:00', 'มาเรียน'),
('ATT102', 'S002', 'T001', '2026-09-25', '08:05:00', '16:00:00', 'มาสาย'),
('ATT103', 'S003', 'T001', '2026-09-25', NULL, NULL, 'ลาป่วย'),
('ATT104', 'S004', 'T001', '2026-09-25', '07:38:00', '16:00:00', 'มาเรียน'),
('ATT105', 'S005', 'T001', '2026-09-25', NULL, NULL, 'ขาด'),
('ATT106', 'S006', 'T002', '2026-09-25', '07:50:00', '16:00:00', 'มาเรียน'),
('ATT107', 'S007', 'T002', '2026-09-25', '08:15:00', '16:00:00', 'มาสาย'),
('ATT108', 'S008', 'T002', '2026-09-25', '07:44:00', '16:00:00', 'มาเรียน'),
('ATT109', 'S009', 'T002', '2026-09-25', NULL, NULL, 'ลากิจ'),
('ATT110', 'S010', 'T002', '2026-09-25', '07:55:00', '16:00:00', 'มาเรียน'),
('ATT111', 'S011', 'T004', '2026-09-25', '07:48:00', '16:00:00', 'มาเรียน'),
('ATT112', 'S012', 'T004', '2026-09-25', '07:52:00', '16:00:00', 'มาเรียน'),
('ATT113', 'S013', 'T004', '2026-09-25', NULL, NULL, 'ขาด'),
('ATT114', 'S014', 'T004', '2026-09-25', '08:20:00', '16:00:00', 'มาสาย'),
('ATT115', 'S015', 'T004', '2026-09-25', '07:40:00', '16:00:00', 'มาเรียน'),
('ATT116', 'S016', 'T005', '2026-09-25', '07:45:00', '16:00:00', 'มาเรียน'),
('ATT117', 'S017', 'T005', '2026-09-25', NULL, NULL, 'ลาป่วย'),
('ATT118', 'S018', 'T005', '2026-09-25', '07:58:00', '16:00:00', 'มาเรียน'),
('ATT119', 'S019', 'T005', '2026-09-25', '07:41:00', '16:00:00', 'มาเรียน'),
('ATT120', 'S020', 'T005', '2026-09-25', NULL, NULL, 'ขาด'),
('ATT202609262302383456', 'S002', 'T001', '2026-09-26', NULL, NULL, 'ลาป่วย');

-- --------------------------------------------------------

--
-- Table structure for table `grades`
--

CREATE TABLE `grades` (
  `grade_id` int(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `subject_id` varchar(50) NOT NULL,
  `academic_year` int(11) NOT NULL,
  `semester` int(11) NOT NULL,
  `total_score` float DEFAULT NULL,
  `grade_result` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `grades`
--

INSERT INTO `grades` (`grade_id`, `student_id`, `subject_id`, `academic_year`, `semester`, `total_score`, `grade_result`) VALUES
(1, 'S001', 'SUB001', 2569, 1, 85, '4'),
(3, 'S001', 'SUB002', 2569, 1, 78, '3.5'),
(6, 'S001', 'SUB003', 2569, 1, 92, '4'),
(9, 'S001', 'SUB004', 2569, 1, 65, '2.5'),
(12, 'S002', 'SUB001', 2569, 1, 88, '4'),
(15, 'S002', 'SUB002', 2569, 1, 74, '3'),
(18, 'S002', 'SUB003', 2569, 1, 80, '3.5'),
(21, 'S002', 'SUB004', 2569, 1, 70, '3'),
(24, 'S003', 'SUB001', 2569, 1, 55, '1.5'),
(27, 'S003', 'SUB002', 2569, 1, 60, '2'),
(30, 'S003', 'SUB003', 2569, 1, 58, '1.5'),
(33, 'S003', 'SUB004', 2569, 1, 62, '2'),
(36, 'S004', 'SUB001', 2569, 1, 95, '4'),
(39, 'S004', 'SUB002', 2569, 1, 89, '4'),
(42, 'S004', 'SUB003', 2569, 1, 91, '4'),
(45, 'S004', 'SUB004', 2569, 1, 85, '4'),
(48, 'S005', 'SUB001', 2569, 1, 72, '3'),
(51, 'S005', 'SUB002', 2569, 1, 68, '2.5'),
(54, 'S005', 'SUB003', 2569, 1, 75, '3'),
(57, 'S005', 'SUB004', 2569, 1, 70, '3'),
(60, 'S006', 'SUB001', 2569, 1, 82, '3.5'),
(63, 'S006', 'SUB002', 2569, 1, 90, '4'),
(66, 'S007', 'SUB001', 2569, 1, 66, '2.5'),
(69, 'S007', 'SUB002', 2569, 1, 71, '3'),
(72, 'S008', 'SUB001', 2569, 1, 77, '3.5'),
(75, 'S008', 'SUB002', 2569, 1, 80, '3.5'),
(78, 'S009', 'SUB001', 2569, 1, 85, '4'),
(81, 'S009', 'SUB002', 2569, 1, 79, '3.5'),
(84, 'S010', 'SUB001', 2569, 1, 60, '2'),
(87, 'S010', 'SUB002', 2569, 1, 64, '2.5'),
(90, 'S011', 'SUB005', 2569, 1, 88, '4'),
(93, 'S011', 'SUB004', 2569, 1, 75, '3'),
(96, 'S012', 'SUB005', 2569, 1, 92, '4'),
(99, 'S012', 'SUB004', 2569, 1, 80, '3.5'),
(102, 'S013', 'SUB005', 2569, 1, 55, '1.5'),
(105, 'S013', 'SUB004', 2569, 1, 60, '2'),
(108, 'S014', 'SUB005', 2569, 1, 70, '3'),
(111, 'S014', 'SUB004', 2569, 1, 68, '2.5'),
(114, 'S015', 'SUB005', 2569, 1, 95, '4'),
(117, 'S015', 'SUB004', 2569, 1, 90, '4'),
(120, 'S016', 'SUB004', 2569, 1, 78, '3.5'),
(123, 'S017', 'SUB004', 2569, 1, 84, '3.5'),
(126, 'S018', 'SUB004', 2569, 1, 58, '1.5'),
(129, 'S019', 'SUB004', 2569, 1, 91, '4'),
(132, 'S020', 'SUB004', 2569, 1, 66, '2.5');

-- --------------------------------------------------------

--
-- Table structure for table `leave_requests`
--

CREATE TABLE `leave_requests` (
  `leave_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `recorded_by_teacher_id` varchar(50) NOT NULL,
  `leave_type` enum('ลาป่วย','ลากิจ') NOT NULL,
  `leave_date` date NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `leave_requests`
--

INSERT INTO `leave_requests` (`leave_id`, `student_id`, `recorded_by_teacher_id`, `leave_type`, `leave_date`, `reason`, `created_at`) VALUES
('LV001', 'S003', 'T001', 'ลาป่วย', '2026-09-25', 'เป็นไข้หวัด มีใบรับรองแพทย์', '2026-09-26 14:45:32'),
('LV002', 'S005', 'T001', 'ลาป่วย', '2026-09-08', 'ปวดท้อง ผู้ปกครองพามาโรงพยาบาล', '2026-09-26 14:45:32'),
('LV003', 'S003', 'T001', 'ลาป่วย', '2026-09-22', 'ไข้หวัดใหญ่ พักรักษาตัวที่บ้าน', '2026-09-26 14:45:32'),
('LV004', 'S004', 'T001', 'ลากิจ', '2026-09-23', 'ลาไปติดต่อราชการกับผู้ปกครอง', '2026-09-26 14:45:32'),
('LV005', 'S009', 'T002', 'ลากิจ', '2026-09-25', 'ลาไปทำธุระที่บ้าน (แจ้งผ่านไลน์)', '2026-09-26 14:45:32'),
('LV006', 'S008', 'T002', 'ลากิจ', '2026-09-23', 'ลาไปงานศพญาติ', '2026-09-26 14:45:32'),
('LV007', 'S013', 'T004', 'ลากิจ', '2026-09-25', 'ลาไปแข่งขันกีฬาระดับจังหวัด', '2026-09-26 14:45:32'),
('LV008', 'S017', 'T005', 'ลาป่วย', '2026-09-22', 'ปวดฟัน ไปพบทันตแพทย์', '2026-09-26 14:45:32'),
('LV009', 'S017', 'T005', 'ลาป่วย', '2026-09-25', 'ยังพักฟื้นจากการถอนฟัน', '2026-09-26 14:45:32'),
('LV010', 'S020', 'T005', 'ลากิจ', '2026-09-22', 'ลาไปช่วยงานที่บ้าน', '2026-09-26 14:45:32'),
('LV202609262302388751', 'S002', 'T001', 'ลาป่วย', '2026-09-26', 'ไข้หวัดใหญ่', '2026-09-26 16:02:38');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `student_id`, `title`, `message`, `created_at`) VALUES
('NOTI20260923180652220', 'S001', 'ถูกหักคะแนนความประพฤติ', 'ผมยาว (-5 คะแนน)', '2026-09-23 11:06:53'),
('NOTI20260923182630814', 'S001', 'ถูกหักคะแนนความประพฤติ', 'ออกนอกบริเวณโรงเรียนโดยไม่ได้รับอนุญาต (-3 คะแนน)', '2026-09-23 11:26:29'),
('NOTI20260924143435584', 'S001', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 15 นาที ถูกหัก 1.5 คะแนน', '2026-09-24 07:34:35'),
('NOTI20260924151449297', 'S001', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 435 นาที ถูกหัก 43.5 คะแนน', '2026-09-24 08:14:48'),
('NOTI20260924151450122', 'S002', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 435 นาที ถูกหัก 43.5 คะแนน', '2026-09-24 08:14:49'),
('NOTI20260924151451891', 'S003', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 435 นาที ถูกหัก 43.5 คะแนน', '2026-09-24 08:14:51'),
('NOTI20260924151453961', 'S004', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 435 นาที ถูกหัก 43.5 คะแนน', '2026-09-24 08:14:52'),
('NOTI20260924151454781', 'S005', 'ถูกหักคะแนนความประพฤติ (มาสาย)', 'เข้าโรงเรียนสาย 435 นาที ถูกหัก 43.5 คะแนน', '2026-09-24 08:14:53');

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `student_id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  `room` varchar(20) DEFAULT NULL,
  `class_no` int(11) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `birth_date` date DEFAULT NULL,
  `blood_group` varchar(5) DEFAULT NULL,
  `parent_name` varchar(100) DEFAULT NULL,
  `parent_phone_number` varchar(20) DEFAULT NULL,
  `advisor_teacher_id` varchar(50) DEFAULT NULL,
  `line_user_id` varchar(100) DEFAULT NULL,
  `is_line_linked` tinyint(1) DEFAULT 0,
  `is_registered` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `password`, `name`, `room`, `class_no`, `phone_number`, `email`, `address`, `birth_date`, `blood_group`, `parent_name`, `parent_phone_number`, `advisor_teacher_id`, `line_user_id`, `is_line_linked`, `is_registered`) VALUES
('S001', '1234567', 'เด็กชายกิตติ มานะ', 'ม.1/1', 1, '089-000-0001', NULL, '1 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', NULL, 'O', 'นายมานะ ใจเย็น', '089-500-0001', 'T001', 'U0001', 1, 1),
('S002', '$2y$12$EOuQTgwEj2sytevppnTvUO3jYP4Z7CA4mwkLJG39u8i2y8MFkCOMS', 'เด็กหญิงกมล สวยงาม', 'ม.1/1', 2, '089-000-0002', NULL, '2 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', NULL, 'A', 'นางสวย สวยงาม', '089-500-0002', 'T001', 'U0002', 1, 1),
('S003', '123456', 'เด็กชายชัยวัฒน์ เก่งกล้า', 'ม.1/1', 3, '089-000-0003', NULL, '3 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', NULL, 'B', 'นายกล้า เก่งกล้า', '089-500-0003', 'T001', 'U0003', 0, 1),
('S004', '123456', 'เด็กหญิงดวงใจ อ่อนหวาน', 'ม.1/1', 4, '089-000-0004', NULL, '4 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', NULL, 'AB', 'นางหวาน อ่อนหวาน', '089-500-0004', 'T001', NULL, 0, 1),
('S005', '123456', 'เด็กชายธนากร มั่งมี', 'ม.1/1', 5, '089-000-0005', NULL, '5 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', NULL, 'O', 'นายมี มั่งมี', '089-500-0005', 'T001', 'U0005', 1, 1),
('S006', '123456', 'เด็กหญิงพิมพ์ชนก ใสสะอาด', 'ม.1/2', 1, '089-000-0006', NULL, '6 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', NULL, 'A', 'นางสะอาด ใสสะอาด', '089-500-0006', 'T002', 'U0006', 1, 1),
('S007', '123456', 'เด็กชายภูมิพัฒน์ แข็งแรง', 'ม.1/2', 2, '089-000-0007', NULL, '7 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', NULL, 'B', 'นายแรง แข็งแรง', '089-500-0007', 'T002', NULL, 0, 1),
('S008', '123456', 'เด็กชายพงศกร ยิ้มแย้ม', 'ม.1/2', 3, '089-000-0008', NULL, '10 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', NULL, 'A', 'นายแย้ม ยิ้มแย้ม', '089-500-0008', 'T002', NULL, 0, 1),
('S009', '123456', 'เด็กหญิงกัลยา สุขใจ', 'ม.1/2', 4, '089-000-0009', NULL, '11 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', NULL, 'B', 'นางใจ สุขใจ', '089-500-0009', 'T002', 'U0009', 1, 1),
('S010', '123456', 'เด็กชายณัฐพล ก้าวไกล', 'ม.1/2', 5, '089-000-0010', NULL, '12 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', NULL, 'O', 'นายไกล ก้าวไกล', '089-500-0010', 'T002', NULL, 0, 1),
('S011', '123456', 'เด็กชายอัครพล มุ่งมั่น', 'ม.2/1', 1, '089-000-0011', NULL, '20 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', NULL, 'A', 'นายมั่น มุ่งมั่น', '089-500-0011', 'T004', 'U0011', 1, 1),
('S012', '123456', 'เด็กหญิงจิรัชญา แสงทอง', 'ม.2/1', 2, '089-000-0012', NULL, '21 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', NULL, 'B', 'นางทอง แสงทอง', '089-500-0012', 'T004', NULL, 0, 1),
('S013', '123456', 'เด็กชายธีรภัทร วงศ์ใหญ่', 'ม.2/1', 3, '089-000-0013', NULL, '22 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', NULL, 'O', 'นายใหญ่ วงศ์ใหญ่', '089-500-0013', 'T004', 'U0013', 1, 1),
('S014', '123456', 'เด็กหญิงปวีณา รักสงบ', 'ม.2/1', 4, '089-000-0014', NULL, '23 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', NULL, 'AB', 'นางสงบ รักสงบ', '089-500-0014', 'T004', NULL, 0, 1),
('S015', '123456', 'เด็กชายกฤษฎา ทองแท้', 'ม.2/1', 5, '089-000-0015', NULL, '24 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', NULL, 'A', 'นายแท้ ทองแท้', '089-500-0015', 'T004', 'U0015', 1, 1),
('S016', '123456', 'เด็กชายวรเมธ ใจกล้า', 'ม.3/1', 1, '089-000-0016', NULL, '30 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', NULL, 'O', 'นายกล้า ใจกล้า', '089-500-0016', 'T005', NULL, 0, 1),
('S017', '123456', 'เด็กหญิงสิริวิมล งามตา', 'ม.3/1', 2, '089-000-0017', NULL, '31 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', NULL, 'B', 'นางตา งามตา', '089-500-0017', 'T005', 'U0017', 1, 1),
('S018', '123456', 'เด็กชายภานุวัฒน์ ยืนหยัด', 'ม.3/1', 3, '089-000-0018', NULL, '32 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', NULL, 'A', 'นายหยัด ยืนหยัด', '089-500-0018', 'T005', NULL, 0, 1),
('S019', '123456', 'เด็กหญิงณิชากร พูนสุข', 'ม.3/1', 4, '089-000-0019', NULL, '33 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', NULL, 'AB', 'นางสุข พูนสุข', '089-500-0019', 'T005', 'U0019', 1, 1),
('S020', '123456', 'เด็กชายชนาธิป เจริญยิ่ง', 'ม.3/1', 5, '089-000-0020', NULL, '34 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', NULL, 'O', 'นายยิ่ง เจริญยิ่ง', '089-500-0020', 'T005', NULL, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `subject_id` varchar(50) NOT NULL,
  `subject_code` varchar(20) NOT NULL,
  `subject_name` varchar(100) NOT NULL,
  `credit` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`subject_id`, `subject_code`, `subject_name`, `credit`) VALUES
('SUB001', 'ค21101', 'คณิตศาสตร์พื้นฐาน 1', 1.5),
('SUB002', 'ท21101', 'ภาษาไทยพื้นฐาน 1', 1.5),
('SUB003', 'ว21101', 'วิทยาศาสตร์พื้นฐาน 1', 1.5),
('SUB004', 'ส21101', 'สังคมและประวัติศาสตร์', 1.5),
('SUB005', 'อ21101', 'ภาษาอังกฤษพื้นฐาน 1', 1.5);

-- --------------------------------------------------------

--
-- Table structure for table `subject_attendance`
--

CREATE TABLE `subject_attendance` (
  `subject_att_id` varchar(50) NOT NULL,
  `schedule_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `date` date NOT NULL,
  `status` enum('มาเรียน','มาสาย','ขาด','ลาป่วย','ลากิจ') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subject_attendance`
--

INSERT INTO `subject_attendance` (`subject_att_id`, `schedule_id`, `student_id`, `date`, `status`) VALUES
('SATT001', 'SCH001', 'S001', '2026-09-08', 'มาเรียน'),
('SATT002', 'SCH001', 'S002', '2026-09-08', 'มาสาย'),
('SATT003', 'SCH001', 'S003', '2026-09-08', 'ขาด'),
('SATT004', 'SCH001', 'S004', '2026-09-08', 'มาเรียน'),
('SATT005', 'SCH001', 'S005', '2026-09-08', 'ลากิจ'),
('SATT101', 'SCH001', 'S001', '2026-09-22', 'มาเรียน'),
('SATT102', 'SCH001', 'S002', '2026-09-22', 'มาสาย'),
('SATT103', 'SCH001', 'S003', '2026-09-22', 'ลาป่วย'),
('SATT104', 'SCH001', 'S004', '2026-09-22', 'มาเรียน'),
('SATT105', 'SCH001', 'S005', '2026-09-22', 'ขาด'),
('SATT106', 'SCH002', 'S001', '2026-09-22', 'มาเรียน'),
('SATT107', 'SCH002', 'S002', '2026-09-22', 'มาเรียน'),
('SATT108', 'SCH002', 'S003', '2026-09-22', 'ลาป่วย'),
('SATT109', 'SCH002', 'S004', '2026-09-22', 'มาเรียน'),
('SATT110', 'SCH002', 'S005', '2026-09-22', 'ขาด'),
('SATT111', 'SCH003', 'S001', '2026-09-23', 'มาเรียน'),
('SATT112', 'SCH003', 'S002', '2026-09-23', 'มาเรียน'),
('SATT113', 'SCH003', 'S003', '2026-09-23', 'มาเรียน'),
('SATT114', 'SCH003', 'S004', '2026-09-23', 'ลากิจ'),
('SATT115', 'SCH003', 'S005', '2026-09-23', 'มาเรียน'),
('SATT116', 'SCH004', 'S006', '2026-09-23', 'มาเรียน'),
('SATT117', 'SCH004', 'S007', '2026-09-23', 'มาสาย'),
('SATT118', 'SCH004', 'S008', '2026-09-23', 'มาเรียน'),
('SATT119', 'SCH004', 'S009', '2026-09-23', 'มาเรียน'),
('SATT120', 'SCH004', 'S010', '2026-09-23', 'ขาด'),
('SATT121', 'SCH005', 'S011', '2026-09-22', 'มาเรียน'),
('SATT122', 'SCH005', 'S012', '2026-09-22', 'มาเรียน'),
('SATT123', 'SCH005', 'S013', '2026-09-22', 'ขาด'),
('SATT124', 'SCH005', 'S014', '2026-09-22', 'มาสาย'),
('SATT125', 'SCH005', 'S015', '2026-09-22', 'มาเรียน'),
('SATT126', 'SCH006', 'S016', '2026-09-22', 'มาเรียน'),
('SATT127', 'SCH006', 'S017', '2026-09-22', 'ลาป่วย'),
('SATT128', 'SCH006', 'S018', '2026-09-22', 'มาเรียน'),
('SATT129', 'SCH006', 'S019', '2026-09-22', 'มาเรียน'),
('SATT130', 'SCH006', 'S020', '2026-09-22', 'ขาด'),
('SATT131', 'SCH007', 'S001', '2026-09-24', 'มาเรียน'),
('SATT132', 'SCH007', 'S002', '2026-09-24', 'มาเรียน'),
('SATT133', 'SCH007', 'S003', '2026-09-24', 'มาเรียน'),
('SATT134', 'SCH007', 'S004', '2026-09-24', 'มาเรียน'),
('SATT135', 'SCH007', 'S005', '2026-09-24', 'มาสาย'),
('SATT136', 'SCH008', 'S006', '2026-09-23', 'มาเรียน'),
('SATT137', 'SCH008', 'S007', '2026-09-23', 'มาเรียน'),
('SATT138', 'SCH008', 'S008', '2026-09-23', 'ลากิจ'),
('SATT139', 'SCH008', 'S009', '2026-09-23', 'มาเรียน'),
('SATT140', 'SCH008', 'S010', '2026-09-23', 'มาเรียน'),
('SATT141', 'SCH009', 'S011', '2026-09-24', 'มาเรียน'),
('SATT142', 'SCH009', 'S012', '2026-09-24', 'มาเรียน'),
('SATT143', 'SCH009', 'S013', '2026-09-24', 'มาเรียน'),
('SATT144', 'SCH009', 'S014', '2026-09-24', 'มาเรียน'),
('SATT145', 'SCH009', 'S015', '2026-09-24', 'ขาด'),
('SATT146', 'SCH010', 'S016', '2026-09-25', 'มาเรียน'),
('SATT147', 'SCH010', 'S017', '2026-09-25', 'ลาป่วย'),
('SATT148', 'SCH010', 'S018', '2026-09-25', 'มาเรียน'),
('SATT149', 'SCH010', 'S019', '2026-09-25', 'มาเรียน'),
('SATT150', 'SCH010', 'S020', '2026-09-25', 'ขาด');

-- --------------------------------------------------------

--
-- Table structure for table `teachers`
--

CREATE TABLE `teachers` (
  `teacher_id` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(100) NOT NULL,
  `department` varchar(100) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `blood_group` varchar(5) DEFAULT NULL,
  `is_disciplinary` tinyint(1) DEFAULT 0,
  `advisor_room` varchar(20) DEFAULT NULL,
  `is_registered` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teachers`
--

INSERT INTO `teachers` (`teacher_id`, `password`, `name`, `department`, `phone_number`, `address`, `blood_group`, `is_disciplinary`, `advisor_room`, `is_registered`) VALUES
('SYSTEM', 'SYSTEM_DISABLED_ACCOUNT', 'ระบบอัตโนมัติ', 'SYSTEM', NULL, NULL, NULL, 0, NULL, 1),
('T001', '$2y$12$2XGaIT7TE3p7o6ehriD7tOObEyUYTJyRoPkEg7oTXa6hwlx3Y93xa', 'ครูสมชาย ใจดี', 'คณิตศาสตร์', '081-111-1111', '12 หมู่ 3 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'O', 0, 'ม.1/1', 1),
('T002', '$2y$12$TboRK3S/5lBRqzNZYbhbres7iSYS36HQtldNRVKKgBgmNLXCxU8y.', 'ครูสุดา รักเรียน', 'ภาษาไทย', '081-222-2222', '45 หมู่ 1 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', 'A', 0, 'ม.1/2', 1),
('T003', '$2y$12$jRB68RSJ5hDdHZoWqsy9n.pjVb3BFOATF7hbz0j/4G3pjaqK78X12', 'ครูอานนท์ ตั้งใจสอน', 'วิทยาศาสตร์', '081-333-3333', '78 หมู่ 5 ต.สะบารัง อ.เมือง จ.ปัตตานี', 'B', 1, NULL, 1),
('T004', '$2y$12$REPLACE_WITH_REAL_BCRYPT_HASH_3', 'ครูวิภา ดูแลดี', 'ภาษาต่างประเทศ', '081-444-4444', '22 หมู่ 2 ต.รูสะมิแล อ.เมือง จ.ปัตตานี', 'AB', 0, 'ม.2/1', 1),
('T005', '$2y$12$REPLACE_WITH_REAL_BCRYPT_HASH_4', 'ครูประเสริฐ นำทาง', 'สังคมศึกษา', '081-555-5555', '9 หมู่ 4 ต.อาเนาะรู อ.เมือง จ.ปัตตานี', 'O', 0, 'ม.3/1', 1);

-- --------------------------------------------------------

--
-- Table structure for table `timetables`
--

CREATE TABLE `timetables` (
  `schedule_id` varchar(50) NOT NULL,
  `teacher_id` varchar(50) NOT NULL,
  `subject_id` varchar(50) NOT NULL,
  `room` varchar(20) NOT NULL,
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `timetables`
--

INSERT INTO `timetables` (`schedule_id`, `teacher_id`, `subject_id`, `room`, `day_of_week`, `start_time`, `end_time`) VALUES
('SCH001', 'T001', 'SUB001', 'ม.1/1', 'Monday', '08:30:00', '09:30:00'),
('SCH002', 'T002', 'SUB002', 'ม.1/1', 'Monday', '09:30:00', '10:30:00'),
('SCH003', 'T003', 'SUB003', 'ม.1/1', 'Tuesday', '08:30:00', '09:30:00'),
('SCH004', 'T003', 'SUB003', 'ม.1/2', 'Tuesday', '09:30:00', '10:30:00'),
('SCH005', 'T004', 'SUB005', 'ม.2/1', 'Monday', '08:30:00', '09:30:00'),
('SCH006', 'T005', 'SUB004', 'ม.3/1', 'Monday', '08:30:00', '09:30:00'),
('SCH007', 'T001', 'SUB001', 'ม.1/1', 'Wednesday', '08:30:00', '09:30:00'),
('SCH008', 'T002', 'SUB002', 'ม.1/2', 'Tuesday', '08:30:00', '09:30:00'),
('SCH009', 'T004', 'SUB005', 'ม.2/1', 'Wednesday', '09:30:00', '10:30:00'),
('SCH010', 'T005', 'SUB004', 'ม.3/1', 'Thursday', '08:30:00', '09:30:00');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `behaviors`
--
ALTER TABLE `behaviors`
  ADD PRIMARY KEY (`behavior_id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `daily_attendance`
--
ALTER TABLE `daily_attendance`
  ADD PRIMARY KEY (`attendance_id`),
  ADD UNIQUE KEY `uq_daily_att` (`student_id`,`date`),
  ADD KEY `scanned_by_teacher_id` (`scanned_by_teacher_id`);

--
-- Indexes for table `grades`
--
ALTER TABLE `grades`
  ADD PRIMARY KEY (`grade_id`),
  ADD UNIQUE KEY `uq_grade_record` (`student_id`,`subject_id`,`academic_year`,`semester`),
  ADD KEY `subject_id` (`subject_id`);

--
-- Indexes for table `leave_requests`
--
ALTER TABLE `leave_requests`
  ADD PRIMARY KEY (`leave_id`),
  ADD UNIQUE KEY `uq_student_leave_date` (`student_id`,`leave_date`),
  ADD KEY `recorded_by_teacher_id` (`recorded_by_teacher_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`student_id`),
  ADD KEY `fk_student_advisor` (`advisor_teacher_id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`subject_id`);

--
-- Indexes for table `subject_attendance`
--
ALTER TABLE `subject_attendance`
  ADD PRIMARY KEY (`subject_att_id`),
  ADD UNIQUE KEY `uq_subject_att` (`schedule_id`,`student_id`,`date`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`teacher_id`),
  ADD UNIQUE KEY `advisor_room` (`advisor_room`);

--
-- Indexes for table `timetables`
--
ALTER TABLE `timetables`
  ADD PRIMARY KEY (`schedule_id`),
  ADD UNIQUE KEY `uq_teacher_slot` (`teacher_id`,`day_of_week`,`start_time`),
  ADD KEY `subject_id` (`subject_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `grades`
--
ALTER TABLE `grades`
  MODIFY `grade_id` int(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=133;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `behaviors`
--
ALTER TABLE `behaviors`
  ADD CONSTRAINT `behaviors_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `behaviors_ibfk_2` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE CASCADE;

--
-- Constraints for table `daily_attendance`
--
ALTER TABLE `daily_attendance`
  ADD CONSTRAINT `daily_attendance_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_attendance_ibfk_2` FOREIGN KEY (`scanned_by_teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE SET NULL;

--
-- Constraints for table `grades`
--
ALTER TABLE `grades`
  ADD CONSTRAINT `grades_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `grades_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE CASCADE;

--
-- Constraints for table `leave_requests`
--
ALTER TABLE `leave_requests`
  ADD CONSTRAINT `leave_requests_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `leave_requests_ibfk_2` FOREIGN KEY (`recorded_by_teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `fk_student_advisor` FOREIGN KEY (`advisor_teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE SET NULL;

--
-- Constraints for table `subject_attendance`
--
ALTER TABLE `subject_attendance`
  ADD CONSTRAINT `subject_attendance_ibfk_1` FOREIGN KEY (`schedule_id`) REFERENCES `timetables` (`schedule_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `subject_attendance_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `timetables`
--
ALTER TABLE `timetables`
  ADD CONSTRAINT `timetables_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `timetables_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
