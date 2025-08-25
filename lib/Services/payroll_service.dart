import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Payroll Management Service
///
/// This service handles all payroll-related operations:
/// - Monthly payroll generation with a fixed salary.
/// - Advance salary deductions.
/// - Payroll status tracking (Paid/Unpaid).
/// - Performance optimizations for frequent generation.
///
/// Key Features:
/// - Fixed monthly salary calculation.
/// - Admin-managed advance salary system.
/// - Automatic deduction of advances from the final salary.
/// - Batch processing for efficiency.
class PayrollService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _payrollCollection = 'payroll';
  static const String _employeesCollection = 'Employees';
  static const String _advancesCollection = 'advances';

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
  /// - Total advance salary taken during the month
  /// 
  /// Parameters:
  /// - monthYear: Format 'YYYY-MM' (e.g., '2024-01')
  /// 
  /// Returns: Future<Map<String, dynamic>> - Generation result with statistics
  static Future<Map<String, dynamic>> generatePayrollForMonth(String monthYear) async {
    try {
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

          // Get total advance for the month
          final totalAdvance = await _getMonthlyAdvanceTotal(empId, monthYear);

          final finalSalary = salary - totalAdvance;

          await _firestore
              .collection(_payrollCollection)
              .doc(monthYear)
              .collection('Employees')
              .doc(empId)
              .set({
            'employeeId': empId,
            'name': emp['name'] ?? '',
            'baseSalary': salary,
            'advanceSalary': totalAdvance,
            'finalSalary': finalSalary,
            'status': 'Unpaid',
            'generatedAt': FieldValue.serverTimestamp(),
            'monthYear': monthYear,
          });

          totalPayroll += finalSalary;
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
      double totalUnpaidAmount = .0;

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

  /// Get monthly advance total for an employee
  static Future<double> _getMonthlyAdvanceTotal(String employeeId, String monthYear) async {
    double totalAdvance = 0.0;

    final advanceSnapshot = await _firestore
        .collection(_advancesCollection)
        .where('employeeId', isEqualTo: employeeId)
        .where('monthYear', isEqualTo: monthYear)
        .get();

    for (final doc in advanceSnapshot.docs) {
      totalAdvance += (doc.data()['amount'] as num).toDouble();
    }

    return totalAdvance;
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

  static Future<void> giveAdvanceSalary({
    required String employeeId,
    required String employeeName,
    required double amount,
    required DateTime date,
  }) async {
    final monthYear = DateFormat('yyyy-MM').format(date);

    await _firestore.collection(_advancesCollection).add({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'monthYear': monthYear,
    });

    // After adding the advance, recalculate and update the employee's payroll for the month
    await _recalculateAndSaveEmployeePayroll(employeeId, monthYear);
  }

  /// Recalculates and saves an employee's payroll for a specific month.
  /// This is called when an advance is given or if an employee's salary changes.
  static Future<void> _recalculateAndSaveEmployeePayroll(String employeeId, String monthYear) async {
    try {
      final employeeDoc = await _firestore.collection(_employeesCollection).doc(employeeId).get();
      if (!employeeDoc.exists) {
        print('Employee $employeeId not found for payroll recalculation.');
        return;
      }

      final empData = employeeDoc.data();
      final baseSalary = double.tryParse(empData?['salary'].toString() ?? '0.0') ?? 0.0;
      final empName = empData?['name'] ?? 'Unknown';

      final totalAdvance = await _getMonthlyAdvanceTotal(employeeId, monthYear);
      final finalSalary = baseSalary - totalAdvance;

      await _firestore
          .collection(_payrollCollection)
          .doc(monthYear)
          .collection('Employees')
          .doc(employeeId)
          .set({
        'employeeId': employeeId,
        'name': empName,
        'baseSalary': baseSalary,
        'advanceSalary': totalAdvance,
        'finalSalary': finalSalary,
        'status': 'Unpaid', // Default to Unpaid on recalculation, or preserve if already Paid
        'generatedAt': FieldValue.serverTimestamp(), // Update timestamp
        'monthYear': monthYear,
      }, SetOptions(merge: true)); // Use merge to update existing fields without overwriting others

      // Clear cache to ensure fresh data is fetched next time
      clearCache();

      print('Payroll for $empName ($employeeId) in $monthYear recalculated and updated.');
    } catch (e) {
      print('Error recalculating payroll for employee $employeeId in $monthYear: $e');
    }
  }
}