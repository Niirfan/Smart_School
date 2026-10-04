# Smart School — วิเคราะห์โค้ดและฐานข้อมูลปัจจุบัน

> ตรวจจาก source code และ SQL dump ใน workspace เมื่อ 4 ตุลาคม 2569 (2026-10-04)
> ขอบเขต: PHP API/Web, Flutter/Dart, SQL dump, OpenAPI และไฟล์ตั้งค่าที่มีผลต่อการทำงาน
> นี่เป็นการอ่านโค้ดแบบ static; ยังไม่ได้เชื่อมฐานข้อมูลจริงหรือรันแอป/ทดสอบ API
> ผู้ใช้แจ้งว่าระบบใช้เพื่อ demo จึงจัดความปลอดภัยเชิง production เป็นบริบท ไม่ใช่รายการงานเร่งด่วน

## ภาพรวม

โปรเจกต์แบ่งเป็น Flutter app สำหรับนักเรียนและครู, PHP REST API, PHP web สำหรับจัดการวิชา/เกรด และ MariaDB schema มีข้อมูลตัวอย่างนักเรียน 20 คน ครู 5 คน บวกบัญชี SYSTEM และวิชา 5 วิชา

จุดที่ทำได้ดีคือมี API client รวมศูนย์, แยก model กับหน้าจอ, ใช้ prepared statements ใน endpoint ส่วนใหญ่, มี unique key ป้องกันเกรด/attendance ซ้ำ และมีการพัฒนาฟีเจอร์ครูต่อเนื่อง

ข้อจำกัดหลักสำหรับ demo คือแอปยังพึ่งพาข้อมูล/ตัวเลือก hardcode หลายจุด, บางหน้าบันทึกข้อมูลเริ่มต้นด้วยค่าตัวอย่าง, หน้ากระดิ่งยังไม่มี backend ใช้งานจริง (ผู้ใช้ระบุว่าลบตาราง notifications แล้ว), ข้อมูล dump อาจไม่ตรงกับฐานข้อมูลที่ deploy และหลาย flow ต้องตรวจด้วยการรันจริงก่อนสรุปว่าใช้งานได้ครบ

## สิ่งที่ตรวจพบและควรทำก่อน demo

1. **ครูบันทึกเกรด:** Subject ID ปัจจุบันตรงกับ SQL (`SUB001`–`SUB005`) และปี/เทอมมาจาก `AcademicYearHelper` แล้ว แต่ dropdown และห้องยัง hardcode และการดึงข้อมูลในหน้าจอเพียงดึงรายชื่อนักเรียน ไม่ได้โหลดคะแนนเดิม ทั้งยังตั้งคะแนนเริ่มต้นเป็น 80 ทุกคน ควรเพิ่ม GET คะแนนตามวิชา/ห้อง/ปี/เทอม แล้วเติมช่องด้วยคะแนนจริงหรือเว้นว่าง และให้ API คืนข้อผิดพลาดเมื่อบางแถวถูกข้าม
2. **ปุ่มแจ้งเตือน:** `api_notifications.php` คืน `notifications: []` เสมอ และแอปมีเมธอดเรียก API แต่ไม่มีข้อมูลตามคำยืนยันว่าลบตารางแล้ว ถ้า demo ไม่ใช้ ให้ซ่อน/ปิดปุ่มและถอด API client/OpenAPI ที่หลงเหลือ หากต้องการใช้ ให้กำหนด storage ใหม่ก่อน
3. **Cron หักคะแนน:** มีการข้ามวันหยุด/สุดสัปดาห์และเช็กเหตุผลซ้ำแล้ว อย่างไรก็ตาม holiday list ฝังในโค้ดและมีวันที่หมายเหตุว่า “ประมาณ”; เงื่อนไข duplicate อิงข้อความ reason ซึ่งเปราะบาง และ morning phase สร้างสถานะขาดก่อนบันทึกเหตุผลซ้ำแล้วข้ามพฤติกรรมได้ ให้ใช้ unique key (student,date,rule/phase) หรือคอลัมน์อ้างอิงที่ชัดเจน และยืนยันวันหยุดตามวันที่ demo
4. **ตารางเรียน/ห้อง/สิทธิ์ครู:** หลายตัวเลือกห้องและบาง action เป็นค่าคงที่ ขณะที่ข้อมูลตารางเรียนใน dump มีเพียง 10 คาบและไม่ครอบคลุมทุกห้อง/วัน ควรเทียบ flow กับข้อมูลจริงที่จะใช้ใน demo และทำให้ dropdown มาจาก API เมื่อขอบเขตข้อมูลเปลี่ยน
5. **ปีการศึกษา:** helper ใช้ พ.ค.–ต.ค. เป็นเทอม 1 และ พ.ย.–เม.ย. เป็นเทอม 2 รวมเมษายนของปีการศึกษาเดิม เหมาะกับกติกาที่ระบุในโค้ด แต่อาจไม่ตรงปฏิทินโรงเรียนจริง ควรตรวจวันที่ demo แล้วปรับกติกาหรือใช้ค่าตั้งระบบ
6. **SQL dump กับฐานข้อมูลจริง:** dump มีตาราง `notifications` และข้อมูล T004/T005 เป็น bcrypt placeholder แต่ผู้ใช้แจ้งว่าลบ notifications แล้ว ความจริงของฐาน deploy ยืนยันจาก dump ไม่ได้ จึงไม่ควรรัน migration เก่าโดยไม่ตรวจ schema ก่อน

## วิเคราะห์รายไฟล์

คำว่า “ข้อเสีย/แนวทางแก้” ด้านล่างเน้นความถูกต้องและประสบการณ์ demo; ประเด็น authentication/token และการจัดการ secret ไม่ถูกจัดเป็นงานเร่งตามบริบทที่ผู้ใช้กำหนด

### Backend PHP API

| ไฟล์ | หน้าที่และข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `backend/api/db.php` | รวมการเชื่อมต่อฐานข้อมูลของ API และตั้ง charset | เป็นการตั้งค่าคงที่ แยกจาก web config; ทำให้สภาพแวดล้อม demo เปลี่ยนยาก ควรใช้ config กลางเดียว |
| `api_login.php` | ตรวจบัญชีนักเรียนและส่งข้อมูลเข้าแอป | ต้องตรวจ response กับ model ให้ตรงกัน; บัญชี demo และรูปแบบรหัสผ่านขึ้นกับ dump ควรเตรียมบัญชีทดสอบที่ใช้ได้จริง |
| `api_teacher_login.php` | แยกการล็อกอินครูจากนักเรียนและคืนข้อมูลครู | ต้องตรวจว่ารูปแบบข้อมูลตรง `TeacherModel` และค่า `is_registered`/สิทธิ์มีในฐานจริง |
| `api_register.php` | รองรับลงทะเบียนบัญชีและแยก account type | ตรวจ flow สมัครซ้ำและการแสดง error ใน UI; เพิ่มข้อความตอบกลับที่ client แสดงได้ชัด |
| `api_forgot_password.php` | มี flow รีเซ็ตรหัสผ่านนักเรียนโดยตรวจอีเมล | ผูกกับ Google identity/config และข้อมูลอีเมลใน DB; ทดสอบกรณี emulator/fallback และ mismatch ก่อน demo |
| `api_dashboard.php` | รวม profile, attendance, conduct และ schedule ใน response เดียว ลดจำนวน request | endpoint มีหลาย query และ fallback บางส่วนอาจซ่อน schema mismatch; แยก error/log ให้ระบุ query ที่ล้มเหลว และเทียบ response กับ `DashboardData` |
| `api_grades.php` | ดึงเกรดนักเรียนและข้อมูลรายวิชา | ให้แน่ใจว่าการคำนวณ GPAX/หน่วยกิตใช้ข้อมูลครบทุกแถวและเรียงปี/เทอมตามต้องการ; UI ต้องมีสถานะกรณีไม่มีเกรด |
| `api_conduct_history.php` | ส่งประวัติคะแนนพฤติกรรมเพื่อแสดงย้อนหลัง | ตรวจการเรียงเวลาและชื่อผู้บันทึกเมื่อผู้บันทึกเป็น SYSTEM; เพิ่ม empty state ที่ชัดเจน |
| `api_student_attendance_history.php` | มี endpoint ประวัติ attendance สำหรับหน้าประวัตินักเรียน | จำกัดจำนวนรายการตามที่ UI คาดหวังและจัดรูปแบบวันที่/สถานะให้สอดคล้อง model; ตรวจช่วง 90 วันที่ระบุใน client/comment |
| `api_full_timetable.php` | จัดข้อมูลตารางเรียนให้นักเรียนตามห้อง | dump มีข้อมูลตารางจำกัด; empty day/รหัสวันต้องถูกจัดการโดย UI และทดสอบ timezone/วันปัจจุบัน |
| `api_teacher_dashboard.php` | รวมตารางวันนี้และสถิติห้องที่ปรึกษา/attendance | query หลายชุดและขึ้นกับ advisor_room; ตรวจกรณีครูไม่มีห้อง/ไม่มีตาราง และ response parsing ของ `TeacherDashboardData` |
| `api_teacher_students.php` | ดึงรายชื่อนักเรียนตามห้องที่ครูดูแล | ตรวจการกรองสิทธิ์และห้องว่าง รวมทั้งให้ UI ไม่สมมติว่ามีห้องชุดเดิม |
| `api_teacher_schedule.php` | ดึงตารางสอนครู | ตรวจการกรองวันและ timezone; UI ปัจจุบันควรทดสอบทั้งวันมีคาบและไม่มีคาบ |
| `api_teacher_attendance.php` | บันทึก/อ่าน daily attendance; มีตรวจครูมีสิทธิ์สแกน, ใช้เวลาจาก server, มี helper กันการตัดคะแนนซ้ำรายวัน | สร้าง/ALTER table ใน request ซึ่งไม่ควรเป็น flow ปกติ; status client ถูกใช้บางกรณี และการกันซ้ำอิง prefix reason; ย้าย schema ไป SQL setup และทำกุญแจ idempotency ชัดเจน |
| `api_teacher_subject_attendance.php` | บันทึก attendance รายคาบและอ่านรายชื่อ | ต้องตรวจ query/สิทธิ์ครูต่อ schedule และ uniqueness; สร้าง test case เดิมซ้ำ, วันข้ามวัน และห้องที่ไม่มีคาบ |
| `api_teacher_conduct.php` | ให้ครูบันทึกคะแนนพฤติกรรมและมีการตรวจบทบาท | ตรวจ validation ของคะแนน/เหตุผลและพฤติกรรมการบันทึกซ้ำ; ใช้ `score_change` schema ที่ตรง dump (`DECIMAL(6,2)`) |
| `api_teacher_leave.php` | รองรับเพิ่ม/อ่าน/ลบประวัติการลา | ตรวจการลบจาก UI, unique student/date และการ sync `daily_attendance`; ควรกำหนด behavior เมื่อบันทึกลาซ้อนกับ attendance |
| `api_teacher_grades.php` | GET นักเรียนตามห้องและคะแนน; POST ใช้ upsert ตาม unique key ใน dump | map วิชาอยู่ใน Flutter ไม่ได้ดึง API; endpoint ข้าม record คะแนนผิดช่วงโดยไม่รายงานรายตัว; เพิ่ม GET เพื่อเติมคะแนนเดิมและรายงาน validation errors |
| `api_notifications.php` | endpoint ยังรักษารูปแบบ response ที่ client คาดหวัง | เป็น stub คืน array ว่างทุกครั้ง และตารางถูกผู้ใช้แจ้งว่าลบแล้ว; ถ้าไม่ใช้ให้ถอดเส้นทาง UI/client/spec หรือสร้าง backend ใหม่ก่อนนำกลับมา |
| `cron_daily_check.php` | ตรวจวันหยุด, phase เช้า/เย็น, การลา และมี transaction; มีความพยายามกันการหักซ้ำ | วันหยุดฝังโค้ด, duplicate อิง reason, attendance อาจถูกเขียนก่อนรู้ว่ามี behavior ซ้ำ; ทำ idempotency ด้วย key/schema และจัดการวันหยุดเป็น config |
| `backend/api/docs.php` | จุดเข้าเอกสาร API (ถ้ามีการใช้งาน) | ตรวจว่าไม่ซ้ำกับ `docs/index.html`; เลือกเอกสารหลักจุดเดียวและรักษา URL ให้ตรง |
| `backend/api/openapi.json` | ระบุสัญญา API สำหรับเครื่องมือ/ผู้พัฒนา | อาจไม่ตรง endpoint ปัจจุบัน โดยเฉพาะ notifications; อัปเดตหลังยืนยัน API และ response จริง |
| `backend/api/docs/openapi.json` | สำเนาสเปกสำหรับหน้าเอกสาร | ซ้ำกับ `backend/api/openapi.json`; ใช้ไฟล์เดียวหรือเพิ่มขั้นตอน sync เพื่อป้องกัน drift |
| `backend/api/docs/index.html` | หน้า Swagger UI ช่วยสำรวจ endpoint | ตรวจ server URL และ CORS/endpoint ที่ยังใช้ได้; ลบ/ปิดรายการ notification หากไม่ใช้ |

### Backend PHP Web

| ไฟล์ | หน้าที่และข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `backend/web/db.php` | เชื่อมต่อ DB ให้หน้าเว็บ PHP | config แยกจาก API ทำให้ค่าต่างกันได้; รวมค่าตั้งหรืออย่างน้อยตรวจให้ชี้ฐานเดียวกัน |
| `backend/web/index.php` | ฟอร์มเข้าใช้ระบบครู | เป็นระบบ web แยกจาก app; ยืนยัน flow login ผิด/ถูกและ redirect บนสภาพแวดล้อม demo |
| `backend/web/dashboard.php` | หน้าหลักหลัง login | ฟีเจอร์/สถิติมีขอบเขตจำกัด; เพิ่มสถานะว่างและลิงก์ที่ใช้งานได้ครบ |
| `backend/web/subjects.php` | จัดการ/แสดงรายวิชา | ตรวจ validation และการบันทึกชื่อ/รหัสซ้ำ; ใช้ `subjects` ใน DB เป็นแหล่งข้อมูลกลาง |
| `backend/web/grades.php` | ฟอร์มบันทึกเกรดแบบเว็บ ตัดเกรดฝั่ง server | label ปีตัวอย่างในฟอร์มเป็น 2567 แม้ข้อมูล dump ใช้ 2569; แก้เป็น dynamic/ตัวเลือก และใช้ upsert หรือแจ้งเมื่อมี record ซ้ำ |
| `backend/web/logout.php` | จบ session หน้าเว็บ | ตรวจว่าล้าง session/cookie และกลับหน้า login ได้ใน flow demo |

### Flutter bootstrap, service และ model

| ไฟล์ | หน้าที่และข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `lib/main.dart` | สร้างแอปและ gate ตาม session ที่กู้คืน | ตรวจกรณี session ผิดรูปแบบ/โหลดค้าง และหน้าเริ่มต้นของ student/teacher |
| `lib/theme/app_theme.dart` | รวมสีและ Theme ใช้ซ้ำได้ | รักษาความสอดคล้องของสี/คอนทราสต์เมื่อเพิ่มหน้าใหม่ |
| `lib/utils/academic_year_helper.dart` | คำนวณปี พ.ศ./เทอมจากวันที่ โดยรับวันที่จำลองได้ | เดือนแบ่งเทอมเป็นกติกา hardcode; เพิ่ม unit test หรืออ่าน config โรงเรียนเมื่อจำเป็น |
| `lib/services/auth_session.dart` | รวมการจำ session นักเรียน/ครูและ biometric preference | ตรวจการสลับ role และ logout; ไม่เก็บ model ที่ stale หลังแก้ profile |
| `lib/services/api_service.dart` | รวม request ของ dashboard, grades, attendance, teacher flows, leave และ notifications | base URL/ค่า default IDs และ room ยังเป็นตัวอย่าง; error handling บาง endpoint ต่างกัน; ย้าย URL/ค่า default เข้าสภาพแวดล้อม และตัด `getNotifications` ถ้าไม่ใช้ |
| `lib/models/student_model.dart` | แปลง JSON นักเรียนเป็น model | ตรวจ optional fields ให้ตรง response profile ล่าสุด รวม guardian/email ที่อาจว่าง |
| `lib/models/teacher_model.dart` | เก็บข้อมูลครู/สิทธิ์และสถิติ | role flag ต้องตรงกับค่าที่ API ส่ง; ไม่มี server-side identity token ตามบริบท demo |
| `lib/models/grade_model.dart` | model ผลการเรียนและ GPAX fields | ตรวจชนิดตัวเลขจาก JSON ที่อาจเป็น String/number และกรณี null |
| `lib/models/attendance_model.dart` | model สถิติ daily attendance | ตรวจการแมปสถานะไทยให้ครบ enum จาก SQL (รวมลา/ขาด/ยังไม่เช็ก) |
| `lib/models/conduct_model.dart` | model ประวัติและคะแนนพฤติกรรม | แยกคะแนนสะสมกับรายการเปลี่ยนคะแนนให้ชัด; ตรวจค่า teacher เป็น SYSTEM |
| `lib/models/schedule_model.dart` | model schedule รายวันและตารางเต็ม | ตรวจชื่อวันจาก API, การเรียงคาบ และกรณีวันไม่มีข้อมูล |
| `lib/models/leave_model.dart` | model ประวัติการลา | ตรวจรูปแบบวันและ nullable reason ให้เข้ากับ API |

### Flutter หน้าจอนักเรียน

| ไฟล์ | หน้าที่และข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `screens/main_navigation.dart` | navigation หลักนักเรียน | ตรวจการคง state เมื่อสลับแท็บและการส่ง student ID จาก session |
| `screens/auth/login_screen.dart` | เข้าระบบนักเรียนและเสนอ biometric unlock | ตรวจ loading/error และไม่ให้ค่าตัวอย่าง ID ปะปนกับ session จริง |
| `screens/auth/register_screen.dart` | สมัคร/ตั้งรหัสครั้งแรก | ทดสอบ validation, account type และข้อความเมื่อลงทะเบียนไม่สำเร็จ |
| `screens/auth/forgot_password_screen.dart` | reset password และ Google sign-in flow | developer fallback เป็น behavior เฉพาะ demo; แสดงสถานะยืนยันให้ชัดและอย่าให้ fallback สับสนกับการยืนยันจริง |
| `screens/home/home_screen.dart` | dashboard นักเรียน; ปัจจุบันแสดงปีผ่าน helper | ปุ่มแจ้งเตือนยังเป็นจุดเชื่อมไป stub; ซ่อน/ปิดเมื่อไม่มีระบบ notification; ตรวจ refresh/error state |
| `screens/home/widgets/student_card.dart` | card ข้อมูลนักเรียนแยกส่วน | แสดงค่า null/รูปตัวอย่างให้สื่อว่าไม่มีข้อมูลจริง |
| `screens/home/widgets/guardian_card.dart` | แสดงข้อมูลผู้ปกครองและโทรออก | ตรวจ permission/เบอร์ว่าง และข้อความเมื่อเปิดโทรศัพท์ไม่ได้ |
| `screens/home/widgets/attendance_card.dart` | แสดงสถิติ attendance | ตรวจค่ารวมกับ API โดยเฉพาะวันที่ไม่มี record |
| `screens/home/widgets/conduct_card.dart` | แสดงคะแนนพฤติกรรม | ให้คะแนนสะสมและเกณฑ์ผ่านตรงกติกาโรงเรียน |
| `screens/home/widgets/schedule_card.dart` | แสดงคาบเรียนวันนี้ | ตรวจ empty state และเวลา/วันให้ตรง timezone |
| `screens/home/widgets/conduct_history_screen.dart` | แสดงประวัติพฤติกรรม | จัดเรียงใหม่ไปเก่า, loading/error/empty ครบ |
| `screens/attendance/student_attendance_history_screen.dart` | โหลด/refresh ประวัติเข้าออกจาก API | ตรวจข้อจำกัดช่วงข้อมูลและรูปแบบวันที่/สถานะ |
| `screens/grades/grades_screen.dart` | แสดงเกรดและ GPA | ตรวจ empty state และตัวเลข GPA สอดคล้อง backend |
| `screens/profile/profile_screen.dart` | แสดงข้อมูลนักเรียนและติดต่อผู้ปกครอง | จากโครงหน้าเป็นการดูข้อมูล; หาก demo ต้องแก้ไข profile ยังไม่มี flow แก้/บันทึกที่ครบ |
| `screens/qr/qr_screen.dart` | แสดง QR ประจำตัวนักเรียน | QR คือรหัสอ้างอิง ไม่ควรถือว่าเป็นหลักฐานสิทธิ์ในระบบ production; สำหรับ demo ตรวจรหัสตรงกับ session |
| `screens/timetable/full_timetable_screen.dart` | ตารางเรียนเต็มสัปดาห์ | ตรวจวันไม่มีคาบและข้อมูลขาดใน SQL dump; วันที่/วันปัจจุบันต้องตรงกับ locale |

### Flutter หน้าจอครู

| ไฟล์ | หน้าที่และข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `screens/teacher/teacher_navigation.dart` | navigation ครูและประกอบหน้าตาม role | ตรวจว่าปุ่ม/แท็บที่ไม่มีสิทธิ์ซ่อนสอดคล้องกับข้อกำหนด demo |
| `screens/teacher/teacher_home_screen.dart` | dashboard ครูและ quick actions | ตาราง/ห้องในฐานมีข้อมูลตัวอย่างจำกัด; ตรวจ empty/loading และการนำทางแต่ละปุ่ม |
| `screens/teacher/teacher_qr_scanner_screen.dart` | สแกนหรือกรอกรหัสนักเรียน | ทดสอบ permission กล้อง, สแกนซ้ำ และผล API; มี fallback manual ที่เป็นประโยชน์ |
| `screens/teacher/teacher_attendance_screen.dart` | เลือกคาบ/วันที่และบันทึกเช็กชื่อรายคาบ | ตรวจว่าครูเห็นเฉพาะคาบตน, วันอนาคต/ย้อนหลัง และสถานะที่ UI ส่งตรงกับ API |
| `screens/teacher/teacher_leave_screen.dart` | บันทึกและลบรายการลา | ทดสอบกรณีซ้ำ/ลบแล้วและ sync กับ daily attendance |
| `screens/teacher/teacher_conduct_screen.dart` | บันทึกคะแนนพฤติกรรม | ตรวจ validation คะแนน/เหตุผลและ feedback หลัง save |
| `screens/teacher/teacher_grades_screen.dart` | บันทึกเกรดเป็นชุด; Subject IDs ตรง SQL และใช้ helper ปี/เทอม | รายวิชา/ห้อง hardcode; คะแนนเริ่มต้น 80 และไม่ได้โหลดคะแนนเดิม; เติมจาก API ก่อนใช้กับข้อมูลจริง |
| `screens/teacher/teacher_profile_screen.dart` | แสดงโปรไฟล์ครูและประวัติ/บันทึกพฤติกรรมตามหน้าที่ | ตรวจว่าการกรอกคะแนนซ้ำ/สิทธิ์ UI/API สอดคล้องกัน และมี empty/error states |

### SQL และเอกสารสัญญา API

| ไฟล์ | ข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `6620310131_smartschool_db (5).sql` | มี schema และ seed data ครบกลุ่มหลัก; `daily_status` เป็น ENUM รองรับ มาเรียน/มาสาย/ลา/ขาด, `score_change DECIMAL(6,2)`, unique key กัน daily attendance/grade/leave/subject attendance ซ้ำ | เป็น snapshot เวลา 1 ต.ค. 2569 ไม่ยืนยัน DB ปัจจุบัน; ยังมี `notifications`; dump มี placeholder password T004/T005; เก็บเป็น fixture/demo และสร้าง migration ที่ตรวจซ้ำได้ ห้ามถือว่าเท่ากับฐาน deploy |
| `backend/api/openapi.json` และ `backend/api/docs/openapi.json` | ช่วยทดลองและอธิบาย API | สเปกสองชุดซ้ำและอาจมี endpoint notification ที่ไม่มี backend จริง; ทำให้เป็นแหล่งเดียวและสร้าง/ตรวจสเปกจาก implementation |
| `backend/api/docs/index.html` | UI สำหรับอ่านและทดลอง API | server URL/นโยบาย CORS อาจไม่ตรง environment; ตรวจ URLs และ endpoints ก่อนนำเสนอ |

### Flutter/Android/Web configuration และ resource

| กลุ่มไฟล์ | หน้าที่/ข้อดี | ข้อเสีย/แนวทางแก้ |
|---|---|---|
| `flutter_application_1/pubspec.yaml`, `pubspec.lock` | dependency manifest และ lock versions ทำให้ build ใช้ชุด package เดิม | lockfile มีประโยชน์และไม่ควรลบ; ตรวจ plugin ที่ต้องใช้จริงและความเข้ากันได้กับ Android/web |
| `analysis_options.yaml` | ตั้ง lint ให้โค้ดสม่ำเสมอ | ใช้ร่วมกับ static analysis ก่อนส่ง demo |
| `README.md` | คำแนะนำเริ่ม Flutter project | ปรับให้มีขั้นตอนรัน API, ตั้ง base URL และบัญชี demo ที่ใช้งานได้ |
| `web/index.html`, `web/manifest.json`, `web/icons/*`, `web/favicon.png` | metadata/icon สำหรับ Flutter web | ตรวจชื่อแอป, icon และ base href ก่อน build web |
| `android/build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`, `gradle/wrapper/gradle-wrapper.properties` | ตั้งค่า build Android/Gradle | ตรวจเวอร์ชัน Java/Gradle/Flutter ที่เครื่อง demo ใช้ |
| `android/app/build.gradle.kts` | config แอป Android และ plugins | ตรวจ application ID/signing/build mode ตามวิธีนำเสนอ |
| `android/app/src/main/AndroidManifest.xml` | ประกาศแอปและ permissions | ตรวจ permission กล้อง/อินเทอร์เน็ตที่ QR/API ใช้จริง |
| `android/app/src/debug/AndroidManifest.xml`, `src/profile/AndroidManifest.xml` | config เฉพาะ build mode | ตรวจไม่ให้ค่า debug-only เป็นเงื่อนไขตอน demo release |
| `android/app/src/main/kotlin/.../MainActivity.kt` | native entry point Flutter | ควรคง minimal หากไม่มี native integration เพิ่ม |
| `android/app/src/main/res/**` | launch screen, styles และ launcher icons | เป็น resource ที่ต้องตรง branding; ไม่ใช่ตรรกะระบบ |
| `android/local.properties` | path SDK เฉพาะเครื่อง | เป็นไฟล์เฉพาะเครื่อง ไม่ควรใช้แทน config ที่ portable |
| `android/.gradle/**` | cache build ที่สร้างอัตโนมัติ | ไม่ใช่ source; เก็บใน ignore/ลบได้เมื่อจำเป็นต้องเคลียร์ build cacheเท่านั้น |
| `debug.log` | บันทึก debug ใน workspace | ไม่ใช่เอกสารระบบ; ตรวจว่ามีข้อมูลส่วนบุคคลก่อนแชร์ และไม่ใช้เป็นหลักฐานสถานะล่าสุด |

## ประเด็นที่เอกสารเก่าแจ้ง แต่ไม่ตรงกับ source/dump ที่ตรวจรอบนี้

- Subject ID ผิดในหน้าครู: **ไม่พบแล้ว**; ใช้ `SUB001`–`SUB005`
- ปี 2568 คงที่ใน dashboard: **ไม่พบแล้ว**; ใช้ `AcademicYearHelper`
- schema `daily_status`/`score_change` ไม่ตรง: **ไม่พบใน SQL dump นี้**; dump ระบุ ENUM ที่รองรับสถานะและ `DECIMAL(6,2)` แต่ API ยังมี DDL runtime จึงควรตรวจฐานจริง
- Notifications: API ยังเป็น stub; dump มีตาราง แต่ผู้ใช้แจ้งว่าลบแล้ว ให้ถือฐานจริงไม่ยืนยันและยังไม่ทำฟีเจอร์นี้
- Cron ซ้ำ/วันหยุด: มีการแก้บางส่วนใน working tree แต่แนวทาง dedupe และ holiday list ยังควรปรับ/ยืนยันก่อนสาธิต

## ลำดับงานที่แนะนำสำหรับ demo

1. ตัดสินใจปิด notifications ใน UI และ OpenAPI ให้สอดคล้องกับการลบตาราง
2. แก้หน้าบันทึกเกรดให้โหลดคะแนนเดิมและไม่มี default 80 ที่อาจเขียนทับข้อมูล
3. ตรวจรอบ demo ของ daily attendance, subject attendance, leave และ cron ด้วยวัน/ข้อมูล seed ที่จะใช้จริง; ยืนยันวันหยุด
4. ตรวจ room/subject options และตารางเรียนให้ตรงกับข้อมูลฐาน demo
5. อัปเดต README ให้ขั้นตอนรัน, URL API, ผู้ใช้ demo และวิธี reset seed data ชัดเจน
6. ก่อนนำขึ้นใช้งานจริงค่อยทำ security hardening แยกจากขอบเขต demo (token, secrets, CORS, cron authentication)

## ขอบเขตและข้อควรระวัง

- ไม่มีการแก้ PHP/Dart/SQL schema ในการทำรายงานนี้
- ไม่ได้ทดสอบเชื่อมต่อฐานข้อมูลหรือรัน Flutter/PHP; ข้อสรุปเป็นการอ่านไฟล์
- ไฟล์ที่มีการแก้ไขค้างอยู่ก่อนเริ่มงาน: `backend/api/cron_daily_check.php`, `flutter_application_1/lib/models/grade_model.dart`, `flutter_application_1/lib/screens/home/home_screen.dart`, `flutter_application_1/lib/screens/home/widgets/attendance_card.dart`, `flutter_application_1/lib/screens/teacher/teacher_grades_screen.dart`, `flutter_application_1/lib/screens/timetable/full_timetable_screen.dart`, `flutter_application_1/lib/utils/academic_year_helper.dart`; การวิเคราะห์อิงเนื้อหาปัจจุบันและไม่ได้แก้ทับไฟล์เหล่านี้
