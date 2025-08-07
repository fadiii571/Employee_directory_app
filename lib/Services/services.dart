import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/kpi_models.dart';
import 'section_shift_service.dart';
import 'employee_service.dart';
import 'attendance_service.dart';
import 'payroll_service.dart';
import 'kpi_service.dart';

/// Core Business Services for Student Project Management App
///
/// This file contains all the main business logic services:
/// - Employee Management (CRUD operations)
/// - Attendance Management (QR-based check-in/out)
/// - Payroll Calculations (30-day fixed cycles)
/// - KPI Calculations (section-aware punctuality)
/// - File Upload Services (images, documents)
/// - PDF Generation Services
///
/// All services use Firebase Firestore as the backend database
/// and include caching mechanisms for performance optimization.

// ==================== GLOBAL CONSTANTS ====================

/// Standard sections available in the system
const List<String> AVAILABLE_SECTIONS = [
  'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
  'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish', 'Supervisors'
];

/// Fixed working days per month for payroll calculations
const int FIXED_WORKING_DAYS_PER_MONTH = 30;

// ==================== CACHE MANAGEMENT ====================

/// Global caches for performance optimization
Map<String, Map<String, dynamic>> _employeeCache = {};
Map<String, Map<String, dynamic>> _kpiCache = {};
Map<String, List<Map<String, dynamic>>> _attendanceHistoryCache = {};

// ==================== EMPLOYEE MANAGEMENT SERVICES ====================

/// DEPRECATED: Use EmployeeService.addEmployee() instead
///
/// This function is kept for backward compatibility but will be removed in future versions.
/// Please migrate to the new EmployeeService for better error handling and performance.
@Deprecated('Use EmployeeService.addEmployee() instead')
Future<void> Addemployee({
  required String name,
  required String number,
  required String state,
  required String district,
  required String salary,
  required String section,
  required String joiningDate,
  required String profileimageUrl,
  required String imageUrl,
  required String location,
  required double latitude,
  required double longitude,
  required double authnumber,
  required BuildContext context,
}) async {
  // Delegate to new service
  final success = await EmployeeService.addEmployee(
    name: name,
    number: number,
    state: state,
    district: district,
    salary: salary,
    section: section,
    joiningDate: joiningDate,
    profileImageUrl: profileimageUrl,
    imageUrl: imageUrl,
    location: location,
    latitude: latitude,
    longitude: longitude,
    authNumber: authnumber,
    context: context,
  );

  if (success && context.mounted) {
    Navigator.pop(context);
  }
}
Future<String?> uploadToFirebaseStorage() async {
  Uint8List? imageBytes;
  String fileName;

  try {
    if (kIsWeb) {
      // Web image picker
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.image,
      );
      if (result == null || result.files.single.bytes == null) return null;

      imageBytes = result.files.single.bytes!;
      fileName = result.files.single.name;
    } else {
      // Mobile image picker
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      imageBytes = await file.readAsBytes();
      fileName = pickedFile.name;
    }

    // Create unique storage path
    final String path = 'employee_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = await ref.putData(imageBytes);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  } catch (e) {
    print("Upload to Firebase failed: $e");
    return null;
  }
}

 Stream<QuerySnapshot> getEmployees({String? section}) {
    if (section == null) {
      return FirebaseFirestore.instance.collection("Employees").snapshots();
    } else {
      return FirebaseFirestore.instance.collection("Employees").where("section", isEqualTo: section).snapshots();
    }
  }
Future<void> deletemp(String id)async{
  await FirebaseFirestore.instance.collection("Employees").doc(id).delete();
}
Future<void> updateemployee({
 required String id,
  required String name,
  required String number,
  required String state,
  required String salary,
  required String section,
  required String location,
  required double latitude,
  required double longitude,
  required bool isActive,
  required bool notify,
  String? profileImageUrl, // Optional profile image update
  String? imageUrl, // Optional document image update
  required BuildContext context,
}) async {
  try {
    Map<String, dynamic> updateData = {
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
      "location": location,
      "latitude": latitude,
      "longitude": longitude,
      'status': isActive,
      'notify': notify,
    };

    // Only update profile image if a new one is provided
    if (profileImageUrl != null) {
      updateData['profileImageUrl'] = profileImageUrl;
    }

    // Only update document image if a new one is provided
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }

    await FirebaseFirestore.instance.collection("Employees").doc(id).update(updateData);

    // Don't pop here - let the calling code handle navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Employee data updated successfully",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}


Future<void> markQRAttendance(String employeeId, String type) async {
  final now = DateTime.now();
  final time = DateFormat('hh:mm a').format(now);

  // Get employee section to determine shift type
  final empDoc = await FirebaseFirestore.instance
      .collection('Employees')
      .doc(employeeId)
      .get();

  if (!empDoc.exists) {
    throw Exception("Employee not found");
  }

  final empData = empDoc.data()!;
  final section = empData['section'] ?? '';

  // Handle Supervisors section differently (9AM-9PM calendar dates)
  if (section.toLowerCase() == 'supervisors') {
    // For supervisors, use calendar date instead of shift date
    final calendarDate = DateTime(now.year, now.month, now.day);
    final date = DateFormat('yyyy-MM-dd').format(calendarDate);

    final recordRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(date)
        .collection('records')
        .doc(employeeId);

    final snapshot = await recordRef.get();

    if (snapshot.exists) {
      await recordRef.update({
        'logs': FieldValue.arrayUnion([
          {'time': time, 'type': type}
        ])
      });
    } else {
      await recordRef.set({
        'name': empData['name'],
        'id': employeeId,
        'section': section,
        'workSchedule': '9AM-9PM',
        'profileImageUrl': empData['profileImageUrl'],
        'logs': [
          {'time': time, 'type': type}
        ]
      });
    }
    return;
  }

  // Calculate shift-aware working date based on section (for non-supervisor sections)
  DateTime shiftDate = _calculateShiftDate(now, section);
  final date = DateFormat('yyyy-MM-dd').format(shiftDate);
  final recordRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(date)
      .collection('records')
      .doc(employeeId);

  final snapshot = await recordRef.get();

  if (snapshot.exists) {
    final existingData = snapshot.data()!;
    final List<dynamic> logs = existingData['logs'] ?? [];

    final alreadyMarked = logs.any((log) => log['type'] == type);
    if (alreadyMarked) {
      throw Exception("Already marked $type today.");
    }

    await recordRef.update({
      'logs': FieldValue.arrayUnion([
        {'time': time, 'type': type}
      ])
    });
  } else {
    await recordRef.set({
      'name': empData['name'],
      'id': employeeId,
      'profileImageUrl': empData['profileImageUrl'],
      'logs': [
        {'time': time, 'type': type}
      ]
    });
  }
}
Future<Map<String, dynamic>> getEmployeeByIdforqr(String id) async {
  final doc = await FirebaseFirestore.instance.collection('Employees').doc(id).get();
  if (!doc.exists) throw Exception("Employee not found");
  return doc.data()!;
}


Future<List<Map<String, dynamic>>> getQRDailyAttendance({
  required String date,
}) async {
  final attendanceRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(date)
      .collection('records');

  final snapshot = await attendanceRef.get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    data['date'] = date;
    return data;
  }).toList();
}


 
 Future<Map<String, List<Map<String, dynamic>>>> fetchAttendanceHistory({
  required DateTime selectedDate,
  required String viewType,
  required String selectedEmployeeId, // Keep for compatibility but not used
  required Map<String, String> employeeNames, // Keep for compatibility but not used
  String selectedSection = '',
}) async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, List<Map<String, dynamic>>> history = {};

  DateTime startDate = selectedDate;
  DateTime endDate = selectedDate;

  if (viewType == 'Weekly') {
    final weekDay = selectedDate.weekday;
    startDate = selectedDate.subtract(Duration(days: weekDay - 1));
    endDate = startDate.add(const Duration(days: 6));
  } else if (viewType == 'Monthly') {
    startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  }

  // PERFORMANCE FIX: Pre-load employee data for section filtering
  Map<String, Map<String, dynamic>> employeeDataCache = {};
  if (selectedSection.isNotEmpty) {
    try {
      // Filter employees by section at database level for maximum performance
      final employeeSnapshot = await firestore
          .collection('Employees')
          .where('section', isEqualTo: selectedSection)
          .get();

      for (final doc in employeeSnapshot.docs) {
        employeeDataCache[doc.id] = doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading employee data: $e');
    }
  }

  // UPDATED: Generate shift-aware date list for attendance lookup
  final dateList = await _generateShiftAwareDateList(startDate, endDate, '');

  for (final date in dateList) {
    final docRef = firestore.collection('attendance').doc(date).collection('records');
    final snapshot = await docRef.get();

    if (snapshot.docs.isEmpty) continue;

    List<Map<String, dynamic>> dayRecords = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // PERFORMANCE FIX: Use cached employee data for section filtering
      String employeeSection = 'Unknown';
      if (selectedSection.isNotEmpty) {
        // If section filter is active, only process employees in cache (pre-filtered by section)
        if (employeeDataCache.containsKey(doc.id)) {
          employeeSection = employeeDataCache[doc.id]?['section'] ?? 'Unknown';
        } else {
          // Employee not in selected section, skip
          continue;
        }
      } else {
        // No section filter, try to get section from global cache or mark as unknown
        employeeSection = _employeeCache[doc.id]?['section'] ?? 'Unknown';
      }

      final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
      final name = data['name'] ?? employeeNames[doc.id] ?? 'Unknown';
      final profileImageUrl = data['profileImageUrl'] ?? '';

      // ✅ Type-safe fallback for missing check-in/out logs
      final checkInLog = logs.firstWhere(
        (log) => log['type'] == 'Check In',
        orElse: () => <String, dynamic>{},
      );
      final checkOutLog = logs.firstWhere(
        (log) => log['type'] == 'Check Out',
        orElse: () => <String, dynamic>{},
      );

      final checkInTime = DateTime.tryParse(checkInLog['time'] ?? '');
      final checkOutTime = DateTime.tryParse(checkOutLog['time'] ?? '');

      Duration totalDuration = Duration.zero;
      if (checkInTime != null && checkOutTime != null && checkOutTime.isAfter(checkInTime)) {
        totalDuration = checkOutTime.difference(checkInTime);
      }

      dayRecords.add({
        'name': name,
        'section': employeeSection,
        'profileImageUrl': profileImageUrl,
        'logs': logs,
        'checkIn': checkInTime?.toIso8601String(),
        'checkOut': checkOutTime?.toIso8601String(),
        'totalHours': totalDuration.inHours,
        'totalMinutes': totalDuration.inMinutes % 60,
        'formattedDuration': _formatDuration(totalDuration),
      });

      // Cache name
      if (!employeeNames.containsKey(doc.id)) {
        employeeNames[doc.id] = name;
      }
    }

    if (dayRecords.isNotEmpty) {
      history[date] = dayRecords;
    }
  }

  return history;
}

/// Generate shift-aware date list for attendance history lookup
Future<List<String>> _generateShiftAwareDateList(
  DateTime startDate,
  DateTime endDate,
  String selectedEmployeeId
) async {
  final firestore = FirebaseFirestore.instance;
  final Set<String> uniqueDates = {};

  // If specific employee selected, get their section for shift-aware dates
  String? employeeSection;
  if (selectedEmployeeId.isNotEmpty) {
    try {
      final empDoc = await firestore.collection('Employees').doc(selectedEmployeeId).get();
      if (empDoc.exists) {
        employeeSection = empDoc.data()?['section'];
      }
    } catch (e) {
      print('Error fetching employee section: $e');
    }
  }

  // Generate date range
  DateTime currentDate = startDate;
  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    if (employeeSection != null) {
      // Use shift-aware date calculation for specific employee
      final shiftDate = _calculateShiftDate(
        DateTime(currentDate.year, currentDate.month, currentDate.day, 12), // Use noon as reference
        employeeSection,
      );
      uniqueDates.add(DateFormat('yyyy-MM-dd').format(shiftDate));
    } else {
      // For "All Employees" view, include both regular dates and potential shift dates
      // This ensures we catch attendance from all sections

      // Regular calendar date
      uniqueDates.add(DateFormat('yyyy-MM-dd').format(currentDate));

      // Also include shift-aware dates for special sections
      for (final section in ['Fancy', 'KK', 'Admin office']) {
        final shiftDate = _calculateShiftDate(
          DateTime(currentDate.year, currentDate.month, currentDate.day, 12),
          section,
        );
        uniqueDates.add(DateFormat('yyyy-MM-dd').format(shiftDate));
      }
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  return uniqueDates.toList()..sort();
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}

Future<void> generatePayrollForMonth(String monthYear) async {
  final _firestore = FirebaseFirestore.instance;

  final employeeSnapshot = await _firestore.collection('Employees').get();
  final year = int.parse(monthYear.split('-')[0]);
  final month = int.parse(monthYear.split('-')[1]);

  // ✅ FIXED: Use 30 working days for every month
  const int fixedWorkingDays = 30;

  for (final employeeDoc in employeeSnapshot.docs) {
    final emp = employeeDoc.data();
    final empId = employeeDoc.id;

    final salary = double.tryParse(emp['salary'].toString()) ?? 0.0;

    // Get attendance and paid leave counts for the month
    int presentDays = await _getMonthlyAttendanceCount(_firestore, empId, year, month);
    int paidLeaves = await _getMonthlyPaidLeaveCount(_firestore, empId, year, month);

    // Calculate based on fixed 30-day working month
    final absentDays = fixedWorkingDays - presentDays - paidLeaves;
    final dailyRate = salary / fixedWorkingDays; // Always divide by 30
    final deduction = dailyRate * absentDays;
    final finalSalary = salary - deduction;

    await _firestore
        .collection('payroll')
        .doc(monthYear)
        .collection('Employees')
        .doc(empId)
        .set({
      'employeeId': empId,
      'name': emp['name'] ?? '',
      'baseSalary': salary,
      'presentDays': presentDays,
      'paidLeaves': paidLeaves,
      'absentDays': absentDays,
      'workingDays': fixedWorkingDays, // Always 30
      'deduction': deduction,
      'finalSalary': finalSalary,
      'status': 'Unpaid',
      'generatedAt': FieldValue.serverTimestamp(),
    });

    print(
        '✅ Generated payroll for ${emp['name']} — Final Salary: ₹${finalSalary.toStringAsFixed(2)}');
  }
}

/// Helper function to count attendance days for a specific month
Future<int> _getMonthlyAttendanceCount(FirebaseFirestore firestore, String employeeId, int year, int month) async {
  int attendanceCount = 0;
  final totalDaysInMonth = DateUtils.getDaysInMonth(year, month);

  for (int day = 1; day <= totalDaysInMonth; day++) {
    final date = DateTime(year, month, day);
    final shiftStart = DateTime(date.year, date.month, date.day, 16);
    final formatted = DateFormat('yyyy-MM-dd').format(shiftStart);

    final attendanceDoc = await firestore
        .collection('attendance')
        .doc(formatted)
        .collection('records')
        .doc(employeeId)
        .get();

    if (attendanceDoc.exists) {
      final logs = List.from(attendanceDoc.data()?['logs'] ?? []);
      final hasCheckIn = logs.any((log) => log['type'] == 'In');

      if (hasCheckIn) {
        attendanceCount++;
      }
    }
  }

  return attendanceCount;
}

/// Helper function to count paid leave days for a specific month
Future<int> _getMonthlyPaidLeaveCount(FirebaseFirestore firestore, String employeeId, int year, int month) async {
  int paidLeaveCount = 0;
  final totalDaysInMonth = DateUtils.getDaysInMonth(year, month);

  for (int day = 1; day <= totalDaysInMonth; day++) {
    final date = DateTime(year, month, day);
    final shiftStart = DateTime(date.year, date.month, date.day, 16);
    final formatted = DateFormat('yyyy-MM-dd').format(shiftStart);

    final paidLeaveDoc = await firestore
        .collection('paid_leaves')
        .doc(formatted)
        .collection('Employees')
        .doc(employeeId)
        .get();

    if (paidLeaveDoc.exists) {
      paidLeaveCount++;
    }
  }

  return paidLeaveCount;
}

/// Update payroll payment status (Paid/Unpaid)
Future<void> updatePayrollStatus(String monthYear, String employeeId, String status) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  await firestore
      .collection('payroll')
      .doc(monthYear)
      .collection('Employees')
      .doc(employeeId)
      .update({
    'status': status,
    'statusUpdatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> markPaidLeave(String employeeId, DateTime date, String reason) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Align with 4PM shift-based day
  DateTime shiftDate = get4PMShiftDate(date);

  final formatted = DateFormat('yyyy-MM-dd').format(shiftDate);
   final empDoc = await firestore.collection('Employees').doc(employeeId).get();
  final employeeName = empDoc.data()?['name'] ?? 'Unknown';
  await firestore
      .collection('paid_leaves')
      .doc(formatted)
      .collection('Employees')
      .doc(employeeId)
      .set({
    'reason': reason,
    'markedAt': FieldValue.serverTimestamp(),
    'employeename':employeeName
  });
}

Future<List<Map<String, dynamic>>> fetchPaidLeaveHistory({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  List<Map<String, dynamic>> history = [];

  final days = endDate.difference(startDate).inDays;
  for (int i = 0; i <= days; i++) {
    final date = startDate.add(Duration(days: i));
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final leaveSnapshot = await FirebaseFirestore.instance
        .collection('paid_leaves')
        .doc(formattedDate)
        .collection('Employees')
        .get();

    for (var doc in leaveSnapshot.docs) {
      final empId = doc.id;
      final data = doc.data();

      // Fetch employee name (optional, if not stored in leave doc)
      final empDoc = await FirebaseFirestore.instance.collection('Employees').doc(empId).get();
      final empName = empDoc.data()?['name'] ?? 'Unknown';

      history.add({
        'employeeId': empId,
        'employeeName': empName,
        'date': formattedDate,
        'reason': data['reason'] ?? '',
      });
    }
  }

  return history;
}

// ==================== ATTENDANCE KPI CALCULATION FUNCTIONS ====================

// Using global cache defined at top of file

/// OPTIMIZATION: Batch fetch attendance data for multiple dates
Future<Map<String, Map<String, dynamic>>> _batchFetchAttendanceData(
  String employeeId,
  List<String> shiftDates
) async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, dynamic>> attendanceData = {};

  // Use Future.wait to fetch all attendance records concurrently
  final futures = shiftDates.map((shiftDate) async {
    try {
      final doc = await firestore
          .collection('attendance')
          .doc(shiftDate)
          .collection('records')
          .doc(employeeId)
          .get();

      if (doc.exists) {
        return MapEntry(shiftDate, doc.data()!);
      }
    } catch (e) {
      print('Error fetching attendance for $shiftDate: $e');
    }
    return null;
  });

  final results = await Future.wait(futures);

  for (final result in results) {
    if (result != null) {
      attendanceData[result.key] = result.value;
    }
  }

  return attendanceData;
}

/// OPTIMIZATION: Batch fetch paid leave data for multiple dates
Future<Map<String, bool>> _batchFetchPaidLeaveData(
  String employeeId,
  List<String> shiftDates
) async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, bool> paidLeaveData = {};

  // Use Future.wait to fetch all paid leave records concurrently
  final futures = shiftDates.map((shiftDate) async {
    try {
      final doc = await firestore
          .collection('paid_leaves')
          .doc(shiftDate)
          .collection('Employees')
          .doc(employeeId)
          .get();

      return MapEntry(shiftDate, doc.exists);
    } catch (e) {
      print('Error fetching paid leave for $shiftDate: $e');
      return MapEntry(shiftDate, false);
    }
  });

  final results = await Future.wait(futures);

  for (final result in results) {
    paidLeaveData[result.key] = result.value;
  }

  return paidLeaveData;
}

/// Optimized: Calculate attendance KPI for a specific employee (with batch queries and caching)
Future<AttendanceKPI> calculateEmployeeAttendanceKPI({
  required String employeeId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final firestore = FirebaseFirestore.instance;

  // Get employee details from cache or Firestore
  Map<String, dynamic> empData;
  if (_employeeCache.containsKey(employeeId)) {
    empData = _employeeCache[employeeId]!;
  } else {
    final empDoc = await firestore.collection('Employees').doc(employeeId).get();
    empData = empDoc.data() ?? {};
    _employeeCache[employeeId] = empData; // Cache for future use
  }

  final employeeName = empData['name'] ?? 'Unknown';
  final section = empData['section'] ?? 'Unknown';

  // Get section shift configuration
  final sectionShift = await SectionShiftService.getSectionShift(section);

  // Calculate shift dates using consistent 4PM-4PM logic for all sections
  List<String> shiftDates = [];
  DateTime currentDate = startDate;

  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    // Use 4PM-4PM logic for all sections (consistent with attendance marking)
    final shiftStart = DateTime(currentDate.year, currentDate.month, currentDate.day, 16);

    // Skip Sunday shifts (company holiday - same as payroll)
    if (shiftStart.weekday != DateTime.sunday) {
      final shiftDateString = DateFormat('yyyy-MM-dd').format(shiftStart);
      shiftDates.add(shiftDateString);
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  // OPTIMIZATION: Batch fetch all attendance and paid leave data
  final attendanceData = await _batchFetchAttendanceData(employeeId, shiftDates);
  final paidLeaveData = await _batchFetchPaidLeaveData(employeeId, shiftDates);

  int totalWorkingDays = shiftDates.length;
  int presentDays = 0;
  int absentDays = 0;
  int lateArrivals = 0;
  int onTimeArrivals = 0;
  int earlyArrivals = 0;

  for (final shiftDate in shiftDates) {
    final attendanceRecord = attendanceData[shiftDate];

    if (attendanceRecord != null) {
      final logs = List<Map<String, dynamic>>.from(attendanceRecord['logs'] ?? []);

      final checkInLog = logs.firstWhere(
        (log) => log['type'] == 'Check In',
        orElse: () => <String, dynamic>{},
      );

      if (checkInLog.isNotEmpty) {
        presentDays++;

        // Check punctuality and early arrival based on section shift
        final checkInTime = checkInLog['time'] as String;

        if (SectionShiftService.isEmployeeLate(checkInTime, sectionShift)) {
          lateArrivals++;
        } else {
          onTimeArrivals++;

          // Check if employee arrived early (bonus point)
          if (SectionShiftService.isEmployeeEarly(checkInTime, sectionShift)) {
            earlyArrivals++;
          }
        }
      }
    } else {
      // Check for paid leave from batched data
      if (!paidLeaveData.containsKey(shiftDate)) {
        absentDays++;
      }
    }
  }

  // Calculate KPI metrics
  final attendanceRate = totalWorkingDays > 0 ? (presentDays / totalWorkingDays) * 100 : 0.0;
  final punctualityRate = presentDays > 0 ? (onTimeArrivals / presentDays) * 100 : 0.0;
  final earlyArrivalRate = presentDays > 0 ? (earlyArrivals / presentDays) * 100 : 0.0;

  return AttendanceKPI(
    employeeId: employeeId,
    employeeName: employeeName,
    section: section,
    attendanceRate: attendanceRate,
    punctualityRate: punctualityRate,
    earlyArrivalRate: earlyArrivalRate,
    totalWorkingDays: totalWorkingDays,
    presentDays: presentDays,
    absentDays: absentDays,
    lateArrivals: lateArrivals,
    onTimeArrivals: onTimeArrivals,
    earlyArrivals: earlyArrivals,
    calculationPeriodStart: startDate,
    calculationPeriodEnd: endDate,
    sectionShift: sectionShift,
  );
}

/// OPTIMIZED: Calculate section-wise attendance summary (with parallel processing)
Future<SectionAttendanceSummary> calculateSectionAttendanceSummary({
  required String sectionName,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final firestore = FirebaseFirestore.instance;

  // Get section shift configuration
  final sectionShift = await SectionShiftService.getSectionShift(sectionName);

  // Get all employees in the section
  final employeeSnapshot = await firestore
      .collection('Employees')
      .where('section', isEqualTo: sectionName)
      .get();

  // OPTIMIZATION: Calculate all employee KPIs in parallel instead of sequentially
  final futures = employeeSnapshot.docs.map((empDoc) =>
    calculateEmployeeAttendanceKPI(
      employeeId: empDoc.id,
      startDate: startDate,
      endDate: endDate,
    )
  );

  final employeeKPIs = await Future.wait(futures);

  double totalAttendanceRate = 0.0;
  double totalPunctualityRate = 0.0;
  double totalEarlyArrivalRate = 0.0;
  int presentEmployees = 0;

  for (final empKPI in employeeKPIs) {
    if (empKPI.presentDays > 0) {
      presentEmployees++;
      totalAttendanceRate += empKPI.attendanceRate;
      totalPunctualityRate += empKPI.punctualityRate;
      totalEarlyArrivalRate += empKPI.earlyArrivalRate;
    }
  }

  final sectionAttendanceRate = presentEmployees > 0 ? totalAttendanceRate / presentEmployees : 0.0;
  final sectionPunctualityRate = presentEmployees > 0 ? totalPunctualityRate / presentEmployees : 0.0;
  final sectionEarlyArrivalRate = presentEmployees > 0 ? totalEarlyArrivalRate / presentEmployees : 0.0;

  return SectionAttendanceSummary(
    sectionName: sectionName,
    sectionShift: sectionShift,
    sectionAttendanceRate: sectionAttendanceRate,
    sectionPunctualityRate: sectionPunctualityRate,
    sectionEarlyArrivalRate: sectionEarlyArrivalRate,
    totalEmployees: employeeSnapshot.docs.length,
    presentEmployees: presentEmployees,
    employeeKPIs: employeeKPIs,
    calculationPeriodStart: startDate,
    calculationPeriodEnd: endDate,
  );
}

// Using global caches defined at top of file

/// OPTIMIZED: Get attendance KPI data with caching and parallel processing
Future<Map<String, dynamic>> getAttendanceKPIData(KPIFilter filter) async {
  // Create cache key based on filter parameters
  final cacheKey = '${filter.employeeId ?? 'all'}_${filter.department ?? 'all'}_${filter.startDate.toIso8601String()}_${filter.endDate.toIso8601String()}';

  // Check cache first
  if (_kpiCache.containsKey(cacheKey)) {
    final cachedData = _kpiCache[cacheKey]!;
    final cacheTime = DateTime.parse(cachedData['cacheTime']);

    // Use cached data if it's less than 5 minutes old
    if (DateTime.now().difference(cacheTime).inMinutes < 5) {
      return {
        'type': cachedData['type'],
        'data': cachedData['data'],
        'cached': true,
      };
    }
  }

  Map<String, dynamic> result;

  if (filter.employeeId != null) {
    // Individual employee KPI
    final employeeKPI = await calculateEmployeeAttendanceKPI(
      employeeId: filter.employeeId!,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
    result = {'type': 'employee', 'data': employeeKPI};
  } else if (filter.department != null) {
    // Section KPI
    final sectionKPI = await calculateSectionAttendanceSummary(
      sectionName: filter.department!,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );
    result = {'type': 'section', 'data': sectionKPI};
  } else {
    // OPTIMIZATION: Calculate all sections in parallel
    final sections = ['Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering', 'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'];

    final futures = sections.map((section) =>
      calculateSectionAttendanceSummary(
        sectionName: section,
        startDate: filter.startDate,
        endDate: filter.endDate,
      )
    );

    final sectionSummaries = await Future.wait(futures);
    result = {'type': 'all_sections', 'data': sectionSummaries};
  }

  // Cache the result
  _kpiCache[cacheKey] = {
    'type': result['type'],
    'data': result['data'],
    'cacheTime': DateTime.now().toIso8601String(),
  };

  // Clean old cache entries (keep only last 10)
  if (_kpiCache.length > 10) {
    final oldestKey = _kpiCache.keys.first;
    _kpiCache.remove(oldestKey);
  }

  return result;
}

/// Clear KPI cache (useful when data is updated)
void clearKPICache() {
  _kpiCache.clear();
  _employeeCache.clear();
  _attendanceHistoryCache.clear();
}

/// OPTIMIZATION: Preload all employee data to cache
Future<void> preloadEmployeeData() async {
  final firestore = FirebaseFirestore.instance;

  try {
    final employeeSnapshot = await firestore.collection('Employees').get();

    for (final doc in employeeSnapshot.docs) {
      _employeeCache[doc.id] = doc.data();
    }

    print('Preloaded ${employeeSnapshot.docs.length} employees to cache');
  } catch (e) {
    print('Error preloading employee data: $e');
  }
}

/// OPTIMIZATION: Batch fetch attendance data for multiple employees and dates
Future<Map<String, Map<String, Map<String, dynamic>>>> _batchFetchMultipleEmployeeAttendance(
  List<String> employeeIds,
  List<String> shiftDates,
) async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, Map<String, dynamic>>> allAttendanceData = {};

  // Initialize the nested map structure
  for (final employeeId in employeeIds) {
    allAttendanceData[employeeId] = {};
  }

  // Create futures for all combinations of employees and dates
  final futures = <Future<void>>[];

  for (final shiftDate in shiftDates) {
    futures.add(() async {
      try {
        final snapshot = await firestore
            .collection('attendance')
            .doc(shiftDate)
            .collection('records')
            .get();

        for (final doc in snapshot.docs) {
          final employeeId = doc.id;
          if (employeeIds.contains(employeeId)) {
            allAttendanceData[employeeId]![shiftDate] = doc.data();
          }
        }
      } catch (e) {
        print('Error fetching attendance for date $shiftDate: $e');
      }
    }());
  }

  await Future.wait(futures);
  return allAttendanceData;
}

/// Save attendance KPI snapshot for historical tracking
Future<void> saveAttendanceKPISnapshot({
  required String type, // 'daily', 'weekly', 'monthly'
  required Map<String, dynamic> kpiData,
  required DateTime calculationDate,
}) async {
  final firestore = FirebaseFirestore.instance;
  final dateKey = DateFormat('yyyy-MM-dd').format(calculationDate);

  await firestore
      .collection('attendance_kpi_snapshots')
      .doc(type)
      .collection('records')
      .doc(dateKey)
      .set({
    'data': kpiData,
    'calculatedAt': FieldValue.serverTimestamp(),
    'calculationDate': calculationDate.toIso8601String(),
  });
}

/// Get historical attendance KPI data
Future<List<Map<String, dynamic>>> getHistoricalAttendanceKPI({
  required String type,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final firestore = FirebaseFirestore.instance;

  final snapshot = await firestore
      .collection('attendance_kpi_snapshots')
      .doc(type)
      .collection('records')
      .where('calculationDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
      .where('calculationDate', isLessThanOrEqualTo: endDate.toIso8601String())
      .orderBy('calculationDate')
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    return data;
  }).toList();
}

/// Helper function to get 4PM-based shift date (same logic as markQRAttendance)
DateTime get4PMShiftDate(DateTime dateTime) {
  if (dateTime.hour < 16) {
    // Before 4PM = previous day's shift
    return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
  } else {
    // 4PM or after = current day's shift
    return DateTime(dateTime.year, dateTime.month, dateTime.day, 16);
  }
}

/// Calculate shift date using 4PM to 4PM logic with extended checkout for special sections
/// Admin Office, KK, and Fancy can checkout until 6PM next day but stored under shift start date
DateTime _calculateShiftDate(DateTime now, String section) {
  final sectionLower = section.toLowerCase();

  // Special handling for Admin Office, KK, and Fancy (extended checkout until 6PM next day)
  if (sectionLower == 'admin office' || sectionLower == 'kk' || sectionLower == 'fancy') {
    if (now.hour < 16) {
      // Before 4PM = could be extended checkout from previous day's shift OR new day
      if (now.hour <= 18) {
        // Before 6PM = extended checkout from previous day's shift
        return DateTime(now.year, now.month, now.day - 1, 16);
      } else {
        // After 6PM = previous day's shift
        return DateTime(now.year, now.month, now.day - 1, 16);
      }
    } else {
      // 4PM or after = current day's shift
      return DateTime(now.year, now.month, now.day, 16);
    }
  } else {
    // Standard sections: 4PM to 4PM logic
    if (now.hour < 16) {
      // Before 4PM = previous day's shift
      return DateTime(now.year, now.month, now.day - 1, 16);
    } else {
      // 4PM or after = current day's shift
      return DateTime(now.year, now.month, now.day, 16);
    }
  }
}

/// Test function to demonstrate 4PM-4PM shift logic with extended checkout
void testShiftDateCalculation() {
  final testTime1 = DateTime(2024, 8, 6, 16, 0); // 4:00 PM Aug 6 (Check-in)
  final testTime2 = DateTime(2024, 8, 7, 18, 0); // 6:00 PM Aug 7 (Extended checkout)
  final testTime3 = DateTime(2024, 8, 7, 16, 0); // 4:00 PM Aug 7 (Standard checkout)

  print('=== 4PM-4PM Shift Logic with Extended Checkout Test ===');
  print('Test Time 1: ${DateFormat('yyyy-MM-dd HH:mm').format(testTime1)} (Check-in 4PM Aug 6)');
  print('Test Time 2: ${DateFormat('yyyy-MM-dd HH:mm').format(testTime2)} (Extended checkout 6PM Aug 7)');
  print('Test Time 3: ${DateFormat('yyyy-MM-dd HH:mm').format(testTime3)} (Standard checkout 4PM Aug 7)');
  print('');

  for (final section in ['Admin office', 'Fancy', 'KK', 'Other']) {
    print('Section: $section');
    if (section == 'Admin office' || section == 'Fancy' || section == 'KK') {
      print('  Type: 4PM-4PM with extended checkout until 6PM next day');
    } else {
      print('  Type: Standard 4PM-4PM');
    }
    print('  4PM Aug 6 → ${DateFormat('yyyy-MM-dd').format(_calculateShiftDate(testTime1, section))}');
    print('  6PM Aug 7 → ${DateFormat('yyyy-MM-dd').format(_calculateShiftDate(testTime2, section))}');
    print('  4PM Aug 7 → ${DateFormat('yyyy-MM-dd').format(_calculateShiftDate(testTime3, section))}');
    print('');
  }
}

/// Test function for attendance history date generation
Future<void> testAttendanceHistoryDates() async {
  final startDate = DateTime(2024, 1, 15);
  final endDate = DateTime(2024, 1, 17);

  print('=== Attendance History Date Generation Test ===');
  print('Date Range: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');
  print('');

  // Test for specific employee (Fancy section)
  print('For Fancy Employee:');
  final fancyDates = await _generateShiftAwareDateList(startDate, endDate, 'fancy_employee_id');
  for (final date in fancyDates) {
    print('  Search Date: $date');
  }
  print('');

  // Test for all employees
  print('For All Employees:');
  final allDates = await _generateShiftAwareDateList(startDate, endDate, '');
  for (final date in allDates) {
    print('  Search Date: $date');
  }
}

