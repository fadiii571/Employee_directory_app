// Section Shift Configuration
class SectionShift {
  final String sectionName;
  final String startTime; // Format: "HH:mm"
  final String endTime;   // Format: "HH:mm"
  final bool isOvernightShift; // If shift crosses midnight

  SectionShift({
    required this.sectionName,
    required this.startTime,
    required this.endTime,
    this.isOvernightShift = false,
  });

  factory SectionShift.fromJson(Map<String, dynamic> json) {
    return SectionShift(
      sectionName: json['sectionName'] ?? '',
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      isOvernightShift: json['isOvernightShift'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionName': sectionName,
      'startTime': startTime,
      'endTime': endTime,
      'isOvernightShift': isOvernightShift,
    };
  }
}

// Simplified Attendance KPI focused on attendance only
class AttendanceKPI {
  final String employeeId;
  final String employeeName;
  final String section;
  final double attendanceRate;
  final double punctualityRate;
  final double earlyArrivalRate;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int lateArrivals;
  final int onTimeArrivals;
  final int earlyArrivals;
  final DateTime calculationPeriodStart;
  final DateTime calculationPeriodEnd;
  final SectionShift sectionShift;

  AttendanceKPI({
    required this.employeeId,
    required this.employeeName,
    required this.section,
    required this.attendanceRate,
    required this.punctualityRate,
    required this.earlyArrivalRate,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateArrivals,
    required this.onTimeArrivals,
    required this.earlyArrivals,
    required this.calculationPeriodStart,
    required this.calculationPeriodEnd,
    required this.sectionShift,
  });

  factory AttendanceKPI.fromJson(Map<String, dynamic> json) {
    return AttendanceKPI(
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      section: json['section'] ?? '',
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
      punctualityRate: (json['punctualityRate'] ?? 0.0).toDouble(),
      earlyArrivalRate: (json['earlyArrivalRate'] ?? 0.0).toDouble(),
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateArrivals: json['lateArrivals'] ?? 0,
      onTimeArrivals: json['onTimeArrivals'] ?? 0,
      earlyArrivals: json['earlyArrivals'] ?? 0,
      calculationPeriodStart: DateTime.parse(json['calculationPeriodStart']),
      calculationPeriodEnd: DateTime.parse(json['calculationPeriodEnd']),
      sectionShift: SectionShift.fromJson(json['sectionShift']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'section': section,
      'attendanceRate': attendanceRate,
      'punctualityRate': punctualityRate,
      'earlyArrivalRate': earlyArrivalRate,
      'totalWorkingDays': totalWorkingDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateArrivals': lateArrivals,
      'onTimeArrivals': onTimeArrivals,
      'earlyArrivals': earlyArrivals,
      'calculationPeriodStart': calculationPeriodStart.toIso8601String(),
      'calculationPeriodEnd': calculationPeriodEnd.toIso8601String(),
      'sectionShift': sectionShift.toJson(),
    };
  }
}

// Section Summary for KPI Dashboard
class SectionAttendanceSummary {
  final String sectionName;
  final SectionShift sectionShift;
  final double sectionAttendanceRate;
  final double sectionPunctualityRate;
  final double sectionEarlyArrivalRate;
  final int totalEmployees;
  final int presentEmployees;
  final List<AttendanceKPI> employeeKPIs;
  final DateTime calculationPeriodStart;
  final DateTime calculationPeriodEnd;

  SectionAttendanceSummary({
    required this.sectionName,
    required this.sectionShift,
    required this.sectionAttendanceRate,
    required this.sectionPunctualityRate,
    required this.sectionEarlyArrivalRate,
    required this.totalEmployees,
    required this.presentEmployees,
    required this.employeeKPIs,
    required this.calculationPeriodStart,
    required this.calculationPeriodEnd,
  });

  factory SectionAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return SectionAttendanceSummary(
      sectionName: json['sectionName'] ?? '',
      sectionShift: SectionShift.fromJson(json['sectionShift']),
      sectionAttendanceRate: (json['sectionAttendanceRate'] ?? 0.0).toDouble(),
      sectionPunctualityRate: (json['sectionPunctualityRate'] ?? 0.0).toDouble(),
      sectionEarlyArrivalRate: (json['sectionEarlyArrivalRate'] ?? 0.0).toDouble(),
      totalEmployees: json['totalEmployees'] ?? 0,
      presentEmployees: json['presentEmployees'] ?? 0,
      employeeKPIs: (json['employeeKPIs'] as List<dynamic>?)
          ?.map((e) => AttendanceKPI.fromJson(e))
          .toList() ?? [],
      calculationPeriodStart: DateTime.parse(json['calculationPeriodStart']),
      calculationPeriodEnd: DateTime.parse(json['calculationPeriodEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionName': sectionName,
      'sectionShift': sectionShift.toJson(),
      'sectionAttendanceRate': sectionAttendanceRate,
      'sectionPunctualityRate': sectionPunctualityRate,
      'sectionEarlyArrivalRate': sectionEarlyArrivalRate,
      'totalEmployees': totalEmployees,
      'presentEmployees': presentEmployees,
      'employeeKPIs': employeeKPIs.map((e) => e.toJson()).toList(),
      'calculationPeriodStart': calculationPeriodStart.toIso8601String(),
      'calculationPeriodEnd': calculationPeriodEnd.toIso8601String(),
    };
  }
}

enum KPITimeFrame {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
}

class KPIFilter {
  final KPITimeFrame timeFrame;
  final DateTime startDate;
  final DateTime endDate;
  final String? department;
  final String? employeeId;

  KPIFilter({
    required this.timeFrame,
    required this.startDate,
    required this.endDate,
    this.department,
    this.employeeId,
  });
}
