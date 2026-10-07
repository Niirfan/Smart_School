-- รีเซ็ตและสร้างชุดวิชา/ครู/ตารางเรียนใหม่สำหรับ DEMO
-- ครู 1 คนต่อ 1 วิชา และวิชา 1 วิชามีครูคนเดียว
-- 0.5 หน่วยกิต=1, 1=2, 1.5=3, 2=4 คาบ/สัปดาห์
-- สำรองฐานข้อมูลก่อนรัน เพราะลบ grades/timetables เดิม

START TRANSACTION;

DELETE FROM timetables;
DELETE FROM grades;
DELETE FROM subjects;

INSERT INTO subjects (subject_id, subject_code, subject_name, credit) VALUES
('SUB016','X60101','ดาราศาสตร์ฟิสิกส์และดาวเคราะห์นอกระบบ',1.5),
('SUB017','X60102','ปัญญาประดิษฐ์เชิงสร้างสรรค์',1.0),
('SUB018','X60103','วิทยาการหุ่นยนต์ใต้น้ำ',2.0),
('SUB019','X60104','วิศวกรรมภูมิอากาศ',1.5),
('SUB020','X60105','เทคโนโลยีควอนตัม',1.0),
('SUB021','X60106','ภาษาศาสตร์มนุษย์ต่างดาว',0.5),
('SUB022','X60107','กฎหมายอวกาศ',1.0),
('SUB023','X60108','ประสาทวิทยาและเทคโนโลยีสมอง',1.5),
('SUB024','X60109','ภูมิศาสตร์สิ่งมีชีวิตสุดขั้ว',1.0),
('SUB025','X60110','ความปลอดภัยไซเบอร์เชิงรุก',2.0),
('SUB026','X60111','ชีววิทยาสังเคราะห์',1.5),
('SUB027','X60112','พลังงานฟิวชัน',2.0),
('SUB028','X60113','วิทยาศาสตร์นิติวิทยาศาสตร์',1.0),
('SUB029','X60114','เกษตรกรรมอวกาศ',0.5),
('SUB030','X60115','ระบบพลังงานทดแทน',1.5),
('SUB031','X60116','การออกแบบโลกเสมือนจริง',1.0),
('SUB032','X60117','การสำรวจมหาสมุทรลึก',2.0),
('SUB033','X60118','การจัดการภัยพิบัติ',1.0),
('SUB034','X60119','สถาปัตยกรรมยั่งยืน',1.5),
('SUB035','X60120','วิทยาศาสตร์ข้อมูล',2.0);

-- เพิ่มครู T006-T020 (T001-T005 ต้องมีอยู่แล้วในฐานข้อมูล)
INSERT IGNORE INTO teachers
(teacher_id, password, name, department, is_disciplinary, is_registered)
VALUES
('T006','demo123','ครูชีววิทยาสังเคราะห์','วิทยาศาสตร์',0,1),
('T007','demo123','ครูพลังงานฟิวชัน','วิทยาศาสตร์',0,1),
('T008','demo123','ครูนิติวิทยาศาสตร์','วิทยาศาสตร์',0,1),
('T009','demo123','ครูเกษตรกรรมอวกาศ','เทคโนโลยี',0,1),
('T010','demo123','ครูพลังงานทดแทน','เทคโนโลยี',0,1),
('T011','demo123','ครูโลกเสมือนจริง','เทคโนโลยี',0,1),
('T012','demo123','ครูมหาสมุทรศาสตร์','วิทยาศาสตร์',0,1),
('T013','demo123','ครูจัดการภัยพิบัติ','สังคมศึกษา',0,1),
('T014','demo123','ครูสถาปัตยกรรมยั่งยืน','ศิลปะและการออกแบบ',0,1),
('T015','demo123','ครูวิทยาศาสตร์ข้อมูล','เทคโนโลยี',0,1),
('T016','demo123','ครูดาราศาสตร์','วิทยาศาสตร์',0,1),
('T017','demo123','ครูปัญญาประดิษฐ์','เทคโนโลยี',0,1),
('T018','demo123','ครูหุ่นยนต์','เทคโนโลยี',0,1),
('T019','demo123','ครูภูมิอากาศ','วิทยาศาสตร์',0,1),
('T020','demo123','ครูเทคโนโลยีควอนตัม','วิทยาศาสตร์',0,1);

CREATE TEMPORARY TABLE ss_days (day_no TINYINT PRIMARY KEY, day_of_week VARCHAR(9));
INSERT INTO ss_days VALUES
(1,'Monday'),(2,'Tuesday'),(3,'Wednesday'),(4,'Thursday'),(5,'Friday');

CREATE TEMPORARY TABLE ss_periods
(period_no TINYINT PRIMARY KEY, start_time TIME, end_time TIME);
INSERT INTO ss_periods VALUES
(1,'08:30:00','09:10:00'),(2,'09:10:00','09:50:00'),
(3,'09:50:00','10:30:00'),(4,'10:30:00','11:10:00'),
(5,'11:10:00','11:50:00'),(6,'12:40:00','13:20:00'),
(7,'13:20:00','14:00:00'),(8,'14:00:00','14:40:00'),
(9,'14:40:00','15:20:00'),(10,'15:20:00','16:00:00');

CREATE TEMPORARY TABLE ss_numbers (n TINYINT PRIMARY KEY);
INSERT INTO ss_numbers VALUES (1),(2),(3),(4);

CREATE TEMPORARY TABLE ss_subject_map
(subject_no TINYINT PRIMARY KEY, subject_id VARCHAR(50), teacher_id VARCHAR(50), room VARCHAR(20), weekly_periods TINYINT);
INSERT INTO ss_subject_map VALUES
(1,'SUB016','T001','ม.1/1',3),(2,'SUB017','T002','ม.1/2',2),
(3,'SUB018','T003','ม.2/1',4),(4,'SUB019','T004','ม.3/1',3),
(5,'SUB020','T005','ม.1/1',2),(6,'SUB021','T006','ม.1/2',1),
(7,'SUB022','T007','ม.2/1',2),(8,'SUB023','T008','ม.3/1',3),
(9,'SUB024','T009','ม.1/1',2),(10,'SUB025','T010','ม.1/2',4),
(11,'SUB026','T011','ม.2/1',3),(12,'SUB027','T012','ม.3/1',4),
(13,'SUB028','T013','ม.1/1',2),(14,'SUB029','T014','ม.1/2',1),
(15,'SUB030','T015','ม.2/1',3),(16,'SUB031','T016','ม.3/1',2),
(17,'SUB032','T017','ม.1/1',4),(18,'SUB033','T018','ม.1/2',2),
(19,'SUB034','T019','ม.2/1',3),(20,'SUB035','T020','ม.3/1',4);

-- ขยายวิชาเป็นจำนวนคาบต่อสัปดาห์ แล้วกระจายลงช่องตารางของห้อง
INSERT INTO timetables
(schedule_id, teacher_id, subject_id, room, day_of_week, start_time, end_time)
SELECT
  CONCAT('NEW_', m.subject_id, '_', LPAD(o.occurrence_no,2,'0')),
  m.teacher_id,
  m.subject_id,
  m.room,
  d.day_of_week,
  p.start_time,
  p.end_time
FROM ss_subject_map m
JOIN ss_numbers n ON n.n <= m.weekly_periods
JOIN (
  SELECT subject_no, n AS occurrence_no
  FROM ss_subject_map
  JOIN ss_numbers ON ss_numbers.n <= ss_subject_map.weekly_periods
) o ON o.subject_no = m.subject_no AND o.occurrence_no = n.n
JOIN ss_days d ON d.day_no = MOD(m.subject_no + n.n - 1, 5) + 1
JOIN ss_periods p ON p.period_no = FLOOR((m.subject_no + n.n - 1) / 5) + 1;

DROP TEMPORARY TABLE ss_subject_map;
DROP TEMPORARY TABLE ss_numbers;
DROP TEMPORARY TABLE ss_periods;
DROP TEMPORARY TABLE ss_days;

COMMIT;

-- เพิ่มเกรดเฉพาะวิชาที่มีอยู่ในตารางเรียน
INSERT INTO grades
(student_id, subject_id, academic_year, semester, total_score, grade_result)
SELECT DISTINCT
  st.student_id,
  t.subject_id,
  2569,
  1,
  80,
  '4'
FROM students st
JOIN timetables t ON 1=1
ON DUPLICATE KEY UPDATE
  total_score = VALUES(total_score),
  grade_result = VALUES(grade_result);

SELECT room, day_of_week, COUNT(*) AS total_periods,
       MIN(start_time) AS first_period, MAX(end_time) AS last_period
FROM timetables
GROUP BY room, day_of_week
ORDER BY room, day_of_week;
