import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'employee_service.dart';


/// Core Business Services for Student Project Management App
///
/// This file contains all the main business logic services:
/// - Employee Management (CRUD operations)
/// - Attendance Management (QR-based check-in/out)
/// - Payroll Calculations (30-day fixed cycles)

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



/// Safely convert any value to String, handling type mismatches
String _safeGetString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is int || value is double) return ''; // For timestamps/numbers, return empty string
  return value.toString();
}

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
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) return null;

      final File file = File(pickedFile.path);
      imageBytes = await file.readAsBytes();
      fileName = pickedFile.name;
    }

    // Create unique storage path with timestamp and random component
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomId = DateTime.now().microsecond; // Additional uniqueness
    final String path = 'employee_images/${timestamp}_${randomId}_$fileName';

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
      ]),
      'lastUpdated': FieldValue.serverTimestamp(),
      // Ensure name and section are present (for existing records that might be missing them)
      'employeeName': empData['name'],
      'name': empData['name'], // Keep both for compatibility
      'section': section,
      'profileImageUrl': _safeGetString(empData['profileImageUrl']),
    });
  } else {
    await recordRef.set({
      'employeeId': employeeId,
      'employeeName': empData['name'],
      'name': empData['name'], // Keep both for compatibility
      'section': section,
      'profileImageUrl': _safeGetString(empData['profileImageUrl']),
      'shiftDate': date,
      'logs': [
        {'time': time, 'type': type}
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
Future<Map<String, dynamic>> getEmployeeByIdforqr(String id) async {
  try {
    // Clean the ID
    final cleanId = id.trim();

    // Debug logging
    debugPrint('Looking for employee with ID: "$cleanId"');

    final doc = await FirebaseFirestore.instance.collection('Employees').doc(cleanId).get();

    if (!doc.exists) {
      debugPrint('Employee document not found for ID: "$cleanId"');
      throw Exception("Employee not found with ID: $cleanId");
    }

    final data = doc.data()!;

    // Check if employee is active
    if (data['isActive'] == false) {
      throw Exception("Employee account is inactive");
    }

    // Add the document ID to the data
    data['id'] = doc.id;

    debugPrint('Found employee: ${data['name']} (${data['section']})');
    return data;

  } catch (e) {
    debugPrint('Error in getEmployeeByIdforqr: $e');
    rethrow;
  }
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
      final employeeId = doc.id;

      // Get employee data - first try from attendance record, then from cache, finally from database
      String employeeName = data['name'] ?? data['employeeName'] ?? 'Unknown';
      String employeeSection = data['section'] ?? 'Unknown';
      String profileImageUrl = _safeGetString(data['profileImageUrl']);

      // If name or section is missing, fetch from employee database
      if (employeeName == 'Unknown' || employeeSection == 'Unknown') {
        try {
          // Check if we have cached employee data
          Map<String, dynamic>? employeeData;

          if (selectedSection.isNotEmpty && employeeDataCache.containsKey(employeeId)) {
            employeeData = employeeDataCache[employeeId];
          } else if (_employeeCache.containsKey(employeeId)) {
            employeeData = _employeeCache[employeeId];
          } else {
            // Fetch from database
            final empDoc = await firestore.collection('Employees').doc(employeeId).get();
            if (empDoc.exists) {
              employeeData = empDoc.data()!;
              // Cache for future use
              _employeeCache[employeeId] = employeeData;
            }
          }

          if (employeeData != null) {
            if (employeeName == 'Unknown') {
              employeeName = employeeData['name'] ?? 'Unknown';
            }
            if (employeeSection == 'Unknown') {
              employeeSection = employeeData['section'] ?? 'Unknown';
            }
            if (profileImageUrl.isEmpty) {
              profileImageUrl = _safeGetString(employeeData['profileImageUrl']);
            }
          }
        } catch (e) {
          debugPrint('Error fetching employee data for $employeeId: $e');
        }
      }

      // Apply section filter if specified
      if (selectedSection.isNotEmpty && employeeSection != selectedSection) {
        continue;
      }

      final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);

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
        'name': employeeName,
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
        employeeNames[doc.id] = employeeName;
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
      // Before 4PM = extended checkout from previous day's shift
      return DateTime(now.year, now.month, now.day - 1, 16);
    } else if (now.hour < 18) {
      // 4PM to 6PM = could be start of current shift OR extended checkout from previous shift
      // We need to determine based on whether it's the same day as shift start or next day

      // If it's the same day as when the shift started (4PM), it's current day's shift
      // If it's the next day, it's extended checkout from previous day's shift
      final currentShiftStart = DateTime(now.year, now.month, now.day, 16);
      final previousShiftStart = DateTime(now.year, now.month, now.day - 1, 16);

      // Check if we're within 26 hours of the previous shift start (4PM yesterday to 6PM today)
      final hoursSincePreviousShift = now.difference(previousShiftStart).inHours;

      if (hoursSincePreviousShift <= 26) {
        // Within extended checkout period - belongs to previous day's shift
        return previousShiftStart;
      } else {
        // New shift starting today
        return currentShiftStart;
      }
    } else {
      // 6PM or after = current day's shift (new shift starts)
      return DateTime(now.year, now.month, now.day, 16);
    }
  } else {
    // Standard sections: 4PM to 4PM logic (no extended checkout)
    if (now.hour < 16) {
      // Before 4PM = previous day's shift
      return DateTime(now.year, now.month, now.day - 1, 16);
    } else {
      // 4PM or after = current day's shift
      return DateTime(now.year, now.month, now.day, 16);
    }
  }
}



