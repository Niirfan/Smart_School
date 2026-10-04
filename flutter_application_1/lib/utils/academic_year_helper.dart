/// Utility สำหรับคำนวณปีการศึกษาและภาคเรียนปัจจุบันแบบอัตโนมัติ
/// ตามปฏิทินของกระทรวงศึกษาธิการไทย:
///   - ภาคเรียนที่ 1: พฤษภาคม – ตุลาคม
///   - ภาคเรียนที่ 2: พฤศจิกายน – มีนาคม (ปีถัดไป)
///   - ช่วงปิดเทอม (เมษายน): ถือเป็นรอยต่อ → ยังนับเป็นภาคเรียน 2 ของปีเดิม
class AcademicYearHelper {
  AcademicYearHelper._();

  /// คำนวณปีการศึกษา (พ.ศ.) จากวันที่ปัจจุบัน
  /// - พ.ค.–ธ.ค. → ปี พ.ศ. ของปีนั้น
  /// - ม.ค.–เม.ย. → ปี พ.ศ. ของปีก่อนหน้า (ยังอยู่ในปีการศึกษาเดิม)
  static int currentAcademicYear([DateTime? now]) {
    final d = now ?? DateTime.now();
    final buddhistYear = d.year + 543;
    // ม.ค.–เม.ย. ยังอยู่ในปีการศึกษาเดียวกับปี พ.ศ. ที่เริ่มเมื่อ พ.ค. ปีก่อน
    return d.month >= 5 ? buddhistYear : buddhistYear - 1;
  }

  /// คำนวณภาคเรียนปัจจุบัน
  /// - พ.ค.–ต.ค. → ภาคเรียนที่ 1
  /// - พ.ย.–เม.ย. → ภาคเรียนที่ 2
  static int currentSemester([DateTime? now]) {
    final d = now ?? DateTime.now();
    return (d.month >= 5 && d.month <= 10) ? 1 : 2;
  }

  /// สตริงแสดงผล เช่น "ภาคเรียนที่ 1/2569"
  static String label([DateTime? now]) {
    return 'ภาคเรียนที่ ${currentSemester(now)}/${currentAcademicYear(now)}';
  }
}
