import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Payroll Management Service
///
/// This service handles all payroll-related operations:
/// - Monthly payroll generation with DYNAMIC working days (Calendar Days - Sundays)
/// - Attendance-based salary calculations
/// - Paid leave management
/// - Sunday leave management (automatic)
/// - Payroll status tracking (Paid/Unpaid)
/// - Performance optimizations for frequent generation
///
/// Key Features:
/// - DYNAMIC working days per month (Calendar Days - Sundays, e.g., Aug 2025 = 26 days)
/// - Admin-managed paid leave system
/// - Sunday shift leave policy (Sunday shifts = automatic leave, no attendance credit)
/// - Automatic deduction calculations
/// - Batch processing for efficiency
class PayrollService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _payrollCollection = 'payroll';
  static const String _employeesCollection = 'Employees';
  static const String _attendanceCollection = 'attendance';
  static const String _paidLeaveCollection = 'paid_leave';
  
  /// Calculate working days per month dynamically
  ///
  /// Working days = Calendar days in month - Sundays in month
  /// This ensures accurate payroll calculations based on actual working days.
  static int getWorkingDaysInMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final sundaysInMonth = _getSundaysInMonth(year, month);
    return daysInMonth - sundaysInMonth;
  }

  // ==================== CACHE MANAGEMENT ====================
  
  /// Cache for payroll data to improve performance
  static final Map<String, Map<String, dynamic>> _payrollCache = {};
  
  /// Clear the payroll cache
  static void clearCache() {
    _payrollCache.clear();
  }

  // ==================== PAYROLL GENERATION ====================
  
  /// Generate payroll for a specific month
  ///
  /// This is the main function for generating monthly payroll.
  /// It processes all employees and calculates their final salary based on:
  /// - Base salary
  /// - Attendance days (check-ins only)
  /// - Paid leave days
  /// - DYNAMIC working days (Calendar Days - Sundays, varies by month)
  /// 
  /// Parameters:
  /// - monthYear: Format 'YYYY-MM' (e.g., '2024-01')
  /// 
  /// Returns: Future<Map<String, dynamic>> - Generation result with statistics
  static Future<Map<String, dynamic>> generatePayrollForMonth(String monthYear) async {
    try {
      final year = int.parse(monthYear.split('-')[0]);
      final month = int.parse(monthYear.split('-')[1]);

      // Get all active employees
      final employeeSnapshot = await _firestore
          .collection(_employeesCollection)
          .where('isActive', isEqualTo: true)
          .get();

      if (employeeSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No active employees found',
          'employeesProcessed': 0,
        };
      }

      int successCount = 0;
      int errorCount = 0;
      double totalPayroll = 0.0;
      final List<String> errors = [];

      // Process each employee
      for (final employeeDoc in employeeSnapshot.docs) {
        try {
          final emp = employeeDoc.data();
          final empId = employeeDoc.id;
          final salary = double.tryParse(emp['salary'].toString()) ?? 0.0;

          if (salary <= 0) {
            errors.add('${emp['name']}: Invalid salary amount');
            errorCount++;
            continue;
          }

          // Get attendance and paid leave counts for the month
          final presentDays = await _getMonthlyAttendanceCount(empId, year, month);
          final paidLeaves = await _getMonthlyPaidLeaveCount(empId, year, month);
          final sundayLeaves = _getSundaysInMonth(year, month);

          // Calculate payroll based on dynamic working days with Sunday leaves
          final workingDays = getWorkingDaysInMonth(year, month);
          final payrollData = _calculatePayroll(
            baseSalary: salary,
            presentDays: presentDays,
            paidLeaves: paidLeaves,
            sundayLeaves: sundayLeaves,
            workingDays: workingDays,
          );

          // Save payroll record
          await _savePayrollRecord(
            monthYear: monthYear,
            employeeId: empId,
            employeeData: emp,
            payrollData: payrollData,
          );

          totalPayroll += payrollData['finalSalary'];
          successCount++;

        } catch (e) {
          final empName = employeeDoc.data()['name'] ?? 'Unknown';
          errors.add('$empName: ${e.toString()}');
          errorCount++;
        }
      }

      // Clear cache
      clearCache();

      return {
        'success': true,
        'message': 'Payroll generated successfully',
        'employeesProcessed': successCount,
        'errors': errorCount,
        'totalPayroll': totalPayroll,
        'errorDetails': errors,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Error generating payroll: ${e.toString()}',
        'employeesProcessed': 0,
      };
    }
  }

  /// Get payroll records for a specific month
  /// 
  /// Parameters:
  /// - monthYear: Format 'YYYY-MM'
  /// 
  /// Returns: Future<List<Map<String, dynamic>>> - List of payroll records
  static Future<List<Map<String, dynamic>>> getPayrollForMonth(String monthYear) async {
    try {
      // Check cache first
      final cacheKey = 'payroll_$monthYear';
      if (_payrollCache.containsKey(cacheKey)) {
        return List<Map<String, dynamic>>.from(_payrollCache[cacheKey]!['records']);
      }

      // Query Firestore
      final snapshot = await _firestore
          .collection(_payrollCollection)
          .doc(monthYear)
          .collection('Employees')
          .orderBy('name')
          .get();

      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Cache the results
      _payrollCache[cacheKey] = {'records': records};

      return records;
    } catch (e) {
      return [];
    }
  }

  /// Update payroll status (Paid/Unpaid)
  /// 
  /// Parameters:
  /// - monthYear: Format 'YYYY-MM'
  /// - employeeId: Employee document ID
  /// - status: 'Paid' or 'Unpaid'
  /// 
  /// Returns: Future<bool> - true if successful
  static Future<bool> updatePayrollStatus({
    required String monthYear,
    required String employeeId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection(_payrollCollection)
          .doc(monthYear)
          .collection('Employees')
          .doc(employeeId)
          .update({
        'status': status,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Clear cache
      clearCache();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get payroll summary for a month
  /// 
  /// Returns statistics about the payroll for the given month
  static Future<Map<String, dynamic>> getPayrollSummary(String monthYear) async {
    try {
      final records = await getPayrollForMonth(monthYear);

      if (records.isEmpty) {
        return {
          'totalEmployees': 0,
          'paidCount': 0,
          'unpaidCount': 0,
          'totalPaidAmount': 0.0,
          'totalUnpaidAmount': 0.0,
          'totalPayroll': 0.0,
        };
      }

      int paidCount = 0;
      int unpaidCount = 0;
      double totalPaidAmount = 0.0;
      double totalUnpaidAmount = 0.0;

      for (final record in records) {
        final status = record['status'] ?? 'Unpaid';
        final finalSalary = (record['finalSalary'] ?? 0.0).toDouble();

        if (status == 'Paid') {
          paidCount++;
          totalPaidAmount += finalSalary;
        } else {
          unpaidCount++;
          totalUnpaidAmount += finalSalary;
        }
      }

      return {
        'totalEmployees': records.length,
        'paidCount': paidCount,
        'unpaidCount': unpaidCount,
        'totalPaidAmount': totalPaidAmount,
        'totalUnpaidAmount': totalUnpaidAmount,
        'totalPayroll': totalPaidAmount + totalUnpaidAmount,
      };
    } catch (e) {
      return {
        'totalEmployees': 0,
        'paidCount': 0,
        'unpaidCount': 0,
        'totalPaidAmount': 0.0,
        'totalUnpaidAmount': 0.0,
        'totalPayroll': 0.0,
        'error': e.toString(),
      };
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Calculate payroll based on attendance and paid leave
  ///
  /// Uses dynamic working days calculation with Sunday shift leave logic:
  ///
  /// LOGIC:
  /// - Working Days = Calendar Days - Sundays (e.g., Aug 2025: 31 - 5 = 26)
  /// - Sunday Shifts = Automatic leave days (NO attendance credit even if employee works)
  /// - Present Days = Only from non-Sunday shifts (Sunday shifts don't count)
  /// - Absent Days = Working Days - Present Days - Paid Leaves
  /// - Daily Rate = Base Salary ÷ Working Days
  /// - Deduction = Daily Rate × Absent Days
  /// - Final Salary = Base Salary - Deduction
  ///
  /// EXAMPLE (August 2025 - 26 working days):
  /// - Present: 20 (from non-Sunday shifts only), Paid Leaves: 2, Sunday Shifts: 5 (automatic leave)
  /// - Absent: 26 - 20 - 2 = 4 days
  /// - Deduction: Only for 4 absent days (Sunday shifts treated as automatic leave)
  static Map<String, dynamic> _calculatePayroll({
    required double baseSalary,
    required int presentDays,
    required int paidLeaves,
    required int sundayLeaves,
    required int workingDays,
  }) {
    // IMPORTANT: workingDays already excludes Sundays (Calendar Days - Sundays)
    // So we only need to subtract present days and paid leaves from working days

    final totalLeaves = paidLeaves + sundayLeaves; // For display purposes
    final absentDays = workingDays - presentDays - paidLeaves; // Actual absent working days
    final dailyRate = baseSalary / workingDays; // Rate based on working days (excludes Sundays)
    final deduction = dailyRate * (absentDays > 0 ? absentDays : 0); // Only deduct for absent working days
    final finalSalary = baseSalary - deduction;

    return {
      'baseSalary': baseSalary,
      'presentDays': presentDays,
      'paidLeaves': paidLeaves,
      'sundayLeaves': sundayLeaves,
      'totalLeaves': totalLeaves,
      'absentDays': absentDays > 0 ? absentDays : 0,
      'workingDays': workingDays, // This should show 26 for August 2025, not 30
      'dailyRate': dailyRate,
      'deduction': deduction,
      'finalSalary': finalSalary,
    };
  }

  /// Save payroll record to Firestore
  static Future<void> _savePayrollRecord({
    required String monthYear,
    required String employeeId,
    required Map<String, dynamic> employeeData,
    required Map<String, dynamic> payrollData,
  }) async {
    await _firestore
        .collection(_payrollCollection)
        .doc(monthYear)
        .collection('Employees')
        .doc(employeeId)
        .set({
      'employeeId': employeeId,
      'name': employeeData['name'] ?? '',
      'section': employeeData['section'] ?? '',
      'salary': employeeData['salary'] ?? '', // Include employee salary
      'baseSalary': payrollData['baseSalary'],
      'presentDays': payrollData['presentDays'],
      'paidLeaves': payrollData['paidLeaves'],
      'sundayLeaves': payrollData['sundayLeaves'],
      'totalLeaves': payrollData['totalLeaves'],
      'absentDays': payrollData['absentDays'],
      'workingDays': payrollData['workingDays'],
      'dailyRate': payrollData['dailyRate'],
      'deduction': payrollData['deduction'],
      'finalSalary': payrollData['finalSalary'],
      'status': 'Unpaid',
      'generatedAt': FieldValue.serverTimestamp(),
      'monthYear': monthYear,
    });
  }

  /// Get monthly attendance count for an employee
  ///
  /// This function uses shift date logic with Sunday shift leave policy:
  /// - Uses 4PM-4PM shift logic to match your attendance system
  /// - Sunday shifts are treated as automatic leave days (no attendance credit)
  /// - Only non-Sunday shifts can contribute to present days count
  static Future<int> _getMonthlyAttendanceCount(String employeeId, int year, int month) async {
    try {
      int presentDays = 0;
      final Set<String> processedShiftDates = {}; // Avoid counting same shift twice

      // Get employee data to determine section for shift calculation
      String employeeSection = '';
      try {
        final employeeDoc = await _firestore
            .collection(_employeesCollection)
            .doc(employeeId)
            .get();
        if (employeeDoc.exists) {
          employeeSection = employeeDoc.data()!['section'] ?? '';
        }
      } catch (e) {
        // Continue with empty section if employee data fetch fails
      }

      // Generate all dates in the month and check for attendance
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);

        // Calculate shift date using the same logic as your attendance system
        final shiftDate = _calculateShiftDateForPayroll(date, employeeSection);
        final shiftDateString = DateFormat('yyyy-MM-dd').format(shiftDate);

        // Skip if we already processed this shift date
        if (processedShiftDates.contains(shiftDateString)) {
          continue;
        }
        processedShiftDates.add(shiftDateString);

        // Apply Sunday shift leave logic
        // If the shift date is a Sunday, treat it as automatic leave (no attendance credit)
        if (shiftDate.weekday == DateTime.sunday) {
          // Sunday shift = automatic leave day, skip attendance check
          continue;
        }

        // Check if employee has attendance record for this shift date (non-Sunday shifts only)
        final attendanceDoc = await _firestore
            .collection(_attendanceCollection)
            .doc(shiftDateString)
            .collection('records')
            .doc(employeeId)
            .get();

        if (attendanceDoc.exists) {
          final logs = List<Map<String, dynamic>>.from(attendanceDoc.data()!['logs'] ?? []);

          // Check if there's a check-in log (only check-ins count for payroll)
          final hasCheckIn = logs.any((log) => log['type'] == 'Check In');
          if (hasCheckIn) {
            presentDays++;
          }
        }
      }

      return presentDays;
    } catch (e) {
      return 0;
    }
  }

  /// Calculate shift date for payroll (matches your attendance system logic)
  ///
  /// This uses the same 4PM-4PM shift logic as your attendance system
  /// with extended checkout support for special sections:
  /// - Admin Office, KK: Extended checkout until 6PM next day
  /// - Fancy: Extended checkout until 10PM next day
  static DateTime _calculateShiftDateForPayroll(DateTime dateTime, String section) {
    final sectionLower = section.toLowerCase();

    // Special handling for extended checkout sections
    if (sectionLower == 'admin office' || sectionLower == 'kk' || sectionLower == 'fancy') {
      if (dateTime.hour < 16) {
        // Before 4PM = could be extended checkout from previous day's shift

        if (sectionLower == 'fancy') {
          // Fancy section: Extended checkout until 10PM next day
          if (dateTime.hour < 22) {
            // Before 10PM = extended checkout from previous day's shift
            return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
          } else {
            // 10PM or after (but before 4PM next day) = previous day's shift
            return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
          }
        } else {
          // Admin Office, KK: Extended checkout until 6PM next day
          if (dateTime.hour < 18) {
            // Before 6PM = extended checkout from previous day's shift
            return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
          } else {
            // 6PM or after (but before 4PM next day) = previous day's shift
            return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
          }
        }
      } else {
        // 4PM or after = current day's shift starts
        return DateTime(dateTime.year, dateTime.month, dateTime.day, 16);
      }
    } else {
      // Standard sections: 4PM to 4PM logic (no extended checkout)
      if (dateTime.hour < 16) {
        // Before 4PM = previous day's shift
        return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
      } else {
        // 4PM or after = current day's shift
        return DateTime(dateTime.year, dateTime.month, dateTime.day, 16);
      }
    }
  }

  /// Count the number of Sundays in a given month
  ///
  /// Parameters:
  /// - year: Year (e.g., 2024)
  /// - month: Month (1-12)
  ///
  /// Returns: int - Number of Sundays in the month
  static int _getSundaysInMonth(int year, int month) {
    int sundayCount = 0;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) {
        sundayCount++;
      }
    }

    return sundayCount;
  }

  /// Get monthly paid leave count for an employee
  static Future<int> _getMonthlyPaidLeaveCount(String employeeId, int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);
      
      final snapshot = await _firestore
          .collection(_paidLeaveCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if payroll exists for a month
  static Future<bool> payrollExistsForMonth(String monthYear) async {
    try {
      final snapshot = await _firestore
          .collection(_payrollCollection)
          .doc(monthYear)
          .collection('Employees')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Delete payroll for a month (admin function)
  static Future<bool> deletePayrollForMonth(String monthYear) async {
    try {
      final snapshot = await _firestore
          .collection(_payrollCollection)
          .doc(monthYear)
          .collection('Employees')
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      // Clear cache
      clearCache();

      return true;
    } catch (e) {
      return false;
    }
  }
}
