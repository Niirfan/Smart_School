-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 172.18.111.42:3306
-- Generation Time: Sep 20, 2026 at 05:36 AM
-- Server version: 10.11.14-MariaDB-0ubuntu0.24.04.1
-- PHP Version: 8.3.33

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
('BEH001', 'S001', 'T003', 5, 'ช่วยเหลือเพื่อนในห้องเรียน', '2026-09-05 03:20:00'),
('BEH002', 'S003', 'T003', -5, 'มาสายซ้ำเกิน 3 ครั้งในเดือน', '2026-09-06 01:15:00'),
('BEH003', 'S002', 'T001', 3, 'ตั้งใจทำการบ้านส่งครบทุกครั้ง', '2026-09-07 06:00:00');

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
  `daily_status` enum('มาเรียน','มาสาย','ลาป่วย','ลากิจ','ลา','ขาด') DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `daily_attendance`
--

INSERT INTO `daily_attendance` (`attendance_id`, `student_id`, `scanned_by_teacher_id`, `date`, `scan_in_time`, `scan_out_time`, `daily_status`) VALUES
('ATT001', 'S001', 'T001', '2026-09-08', '07:45:00', '16:00:00', 'มาเรียน'),
('ATT002', 'S002', 'T001', '2026-09-08', '08:10:00', '16:00:00', 'มาสาย'),
('ATT003', 'S003', 'T001', '2026-09-08', NULL, NULL, 'ขาด'),
('ATT004', 'S004', 'T001', '2026-09-08', '07:50:00', '16:00:00', 'มาเรียน'),
('ATT005', 'S005', 'T001', '2026-09-08', NULL, NULL, 'ลา'),
('ATT006', 'S001', 'T001', '2026-09-09', '07:40:00', '16:00:00', 'มาเรียน'),
('ATT007', 'S002', 'T001', '2026-09-09', '07:48:00', '16:00:00', 'มาเรียน');

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
(1, 'S001', 'SUB001', 2569, 1, 85, '4');

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
  `address` text DEFAULT NULL,
  `blood_group` varchar(5) DEFAULT NULL,
  `parent_name` varchar(100) DEFAULT NULL,
  `parent_phone_number` varchar(20) DEFAULT NULL,
  `advisor_teacher_id` varchar(50) DEFAULT NULL,
  `line_user_id` varchar(100) DEFAULT NULL,
  `is_line_linked` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`student_id`, `password`, `name`, `room`, `class_no`, `phone_number`, `address`, `blood_group`, `parent_name`, `parent_phone_number`, `line_user_id`, `is_line_linked`) VALUES
('S001', '123456', 'เด็กชายกิตติ มานะ', 'ม.1/1', 1, '089-000-0001', '1 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'O', 'นายมานะ ใจเย็น', '089-500-0001', 'U0001', 1),
('S002', '123456', 'เด็กหญิงกมล สวยงาม', 'ม.1/1', 2, '089-000-0002', '2 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'A', 'นางสวย สวยงาม', '089-500-0002', 'U0002', 1),
('S003', '123456', 'เด็กชายชัยวัฒน์ เก่งกล้า', 'ม.1/1', 3, '089-000-0003', '3 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'B', 'นายกล้า เก่งกล้า', '089-500-0003', 'U0003', 0),
('S004', '123456', 'เด็กหญิงดวงใจ อ่อนหวาน', 'ม.1/1', 4, '089-000-0004', '4 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'AB', 'นางหวาน อ่อนหวาน', '089-500-0004', NULL, 0),
('S005', '123456', 'เด็กชายธนากร มั่งมี', 'ม.1/1', 5, '089-000-0005', '5 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'O', 'นายมี มั่งมี', '089-500-0005', 'U0005', 1),
('S006', '123456', 'เด็กหญิงพิมพ์ชนก ใสสะอาด', 'ม.1/2', 1, '089-000-0006', '6 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', 'A', 'นางสะอาด ใสสะอาด', '089-500-0006', 'U0006', 1),
('S007', '123456', 'เด็กชายภูมิพัฒน์ แข็งแรง', 'ม.1/2', 2, '089-000-0007', '7 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', 'B', 'นายแรง แข็งแรง', '089-500-0007', NULL, 0);

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
('SUB004', 'ส21101', 'สังคมและประวัติศาสตร์', 1.5);

-- --------------------------------------------------------

--
-- Table structure for table `subject_attendance`
--

CREATE TABLE `subject_attendance` (
  `subject_att_id` varchar(50) NOT NULL,
  `schedule_id` varchar(50) NOT NULL,
  `student_id` varchar(50) NOT NULL,
  `date` date NOT NULL,
  `status` enum('มาเรียน','มาสาย','ขาด','ลา') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subject_attendance`
--

INSERT INTO `subject_attendance` (`subject_att_id`, `schedule_id`, `student_id`, `date`, `status`) VALUES
('SATT001', 'SCH001', 'S001', '2026-09-08', 'มาเรียน'),
('SATT002', 'SCH001', 'S002', '2026-09-08', 'มาสาย'),
('SATT003', 'SCH001', 'S003', '2026-09-08', 'ขาด'),
('SATT004', 'SCH001', 'S004', '2026-09-08', 'มาเรียน'),
('SATT005', 'SCH001', 'S005', '2026-09-08', 'ลา');

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
  `advisor_room` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `teachers`
--

INSERT INTO `teachers` (`teacher_id`, `password`, `name`, `department`, `phone_number`, `address`, `blood_group`, `is_disciplinary`, `advisor_room`) VALUES
('T001', '123456', 'ครูสมชาย ใจดี', 'คณิตศาสตร์', '081-111-1111', '12 หมู่ 3 ต.บ้านโพธิ์ อ.เมือง จ.ปัตตานี', 'O', 0),
('T002', '123456', 'ครูสุดา รักเรียน', 'ภาษาไทย', '081-222-2222', '45 หมู่ 1 ต.ยะรัง อ.ยะรัง จ.ปัตตานี', 'A', 0),
('T003', '123456', 'ครูอานนท์ ตั้งใจสอน', 'วิทยาศาสตร์', '081-333-3333', '78 หมู่ 5 ต.สะบารัง อ.เมือง จ.ปัตตานี', 'B', 1);

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
('SCH004', 'T003', 'SUB003', 'ม.1/2', 'Tuesday', '09:30:00', '10:30:00');

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
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`student_id`);

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
  ADD PRIMARY KEY (`teacher_id`);

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
  MODIFY `grade_id` int(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

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
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

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
