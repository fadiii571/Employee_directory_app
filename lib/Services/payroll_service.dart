import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Payroll Management Service
/// 
/// This service handles all payroll-related operations:
/// - Monthly payroll generation with fixed 30-day cycles
/// - Attendance-based salary calculations
/// - Paid leave management
/// - Payroll status tracking (Paid/Unpaid)
/// - Performance optimizations for frequent generation
/// 
/// Key Features:
/// - Fixed 30 working days per month (not calendar days)
/// - Admin-managed paid leave system
/// - Automatic deduction calculations
/// - Batch processing for efficiency
class PayrollService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _payrollCollection = 'payroll';
  static const String _employeesCollection = 'Employees';
  static const String _attendanceCollection = 'attendance';
  static const String _paidLeaveCollection = 'paid_leave';
  
  /// Fixed working days per month for payroll calculations
  static const int fixedWorkingDaysPerMonth = 30;

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
  /// - Attendance days
  /// - Paid leave days
  /// - Fixed 30-day working month
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

          // Calculate payroll based on fixed 30-day working month
          final payrollData = _calculatePayroll(
            baseSalary: salary,
            presentDays: presentDays,
            paidLeaves: paidLeaves,
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
  /// Uses fixed 30-day working month logic:
  /// - Total working days = 30 (always)
  /// - Absent days = 30 - present days - paid leave days
  /// - Daily rate = base salary ÷ 30
  /// - Deduction = daily rate × absent days
  /// - Final salary = base salary - deduction
  static Map<String, dynamic> _calculatePayroll({
    required double baseSalary,
    required int presentDays,
    required int paidLeaves,
  }) {
    // Calculate based on fixed 30-day working month
    final absentDays = fixedWorkingDaysPerMonth - presentDays - paidLeaves;
    final dailyRate = baseSalary / fixedWorkingDaysPerMonth;
    final deduction = dailyRate * absentDays;
    final finalSalary = baseSalary - deduction;

    return {
      'baseSalary': baseSalary,
      'presentDays': presentDays,
      'paidLeaves': paidLeaves,
      'absentDays': absentDays,
      'workingDays': fixedWorkingDaysPerMonth,
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
      'baseSalary': payrollData['baseSalary'],
      'presentDays': payrollData['presentDays'],
      'paidLeaves': payrollData['paidLeaves'],
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
  static Future<int> _getMonthlyAttendanceCount(String employeeId, int year, int month) async {
    try {
      int presentDays = 0;
      
      // Generate all dates in the month
      final daysInMonth = DateTime(year, month + 1, 0).day;
      
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        
        // Check if employee has attendance record for this date
        final attendanceDoc = await _firestore
            .collection(_attendanceCollection)
            .doc(dateString)
            .collection('records')
            .doc(employeeId)
            .get();

        if (attendanceDoc.exists) {
          final logs = List<Map<String, dynamic>>.from(attendanceDoc.data()!['logs'] ?? []);
          
          // Check if there's a check-in log
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
