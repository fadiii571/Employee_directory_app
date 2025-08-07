import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Shift Rotation Service for Admin Office
/// 
/// Manages alternating shifts for Admin Office employees where:
/// - 2 employees work alternating shifts (when one is present, other is absent)
/// - Both work 4PM-4PM with extended checkout until 6PM
/// - System tracks which employee should work on which day
/// - Automatic rotation scheduling and validation
class ShiftRotationService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _rotationCollection = 'shift_rotations';
  static const String _adminOfficeSection = 'Admin office';
  
  // Cache for performance
  static Map<String, Map<String, dynamic>>? _rotationCache;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  // ==================== MAIN METHODS ====================
  
  /// Set up shift rotation for Admin Office employees
  /// 
  /// Parameters:
  /// - employee1Id: First employee ID
  /// - employee2Id: Second employee ID  
  /// - startDate: When rotation starts
  /// - employee1StartsFirst: Whether employee1 works the first shift
  /// 
  /// Returns: Success status and message
  static Future<Map<String, dynamic>> setupShiftRotation({
    required String employee1Id,
    required String employee2Id,
    required DateTime startDate,
    required bool employee1StartsFirst,
  }) async {
    try {
      // Validate employees are in Admin Office
      final validation = await _validateAdminOfficeEmployees([employee1Id, employee2Id]);
      if (!validation['isValid']) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }
      
      final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
      
      // Create rotation configuration
      final rotationConfig = {
        'employee1Id': employee1Id,
        'employee1Name': validation['employee1Name'],
        'employee2Id': employee2Id,
        'employee2Name': validation['employee2Name'],
        'startDate': startDateString,
        'employee1StartsFirst': employee1StartsFirst,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      // Save to Firestore
      await _firestore
          .collection(_rotationCollection)
          .doc(_adminOfficeSection)
          .set(rotationConfig);
      
      // Clear cache
      _rotationCache = null;
      
      return {
        'success': true,
        'message': 'Shift rotation setup successfully for Admin Office',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error setting up shift rotation: $e',
      };
    }
  }
  
  /// Get which employee should work on a specific date
  /// 
  /// Parameters:
  /// - date: The shift date to check
  /// 
  /// Returns: Employee ID who should work, or null if no rotation set
  static Future<String?> getScheduledEmployee(DateTime date) async {
    try {
      await _ensureCacheIsValid();
      
      if (_rotationCache == null || !_rotationCache!.containsKey(_adminOfficeSection)) {
        return null; // No rotation configured
      }
      
      final rotation = _rotationCache![_adminOfficeSection]!;
      
      if (rotation['isActive'] != true) {
        return null; // Rotation is disabled
      }
      
      final startDate = DateTime.parse(rotation['startDate']);
      final employee1Id = rotation['employee1Id'] as String;
      final employee2Id = rotation['employee2Id'] as String;
      final employee1StartsFirst = rotation['employee1StartsFirst'] as bool;
      
      // Calculate days since rotation started
      final daysSinceStart = date.difference(startDate).inDays;
      
      if (daysSinceStart < 0) {
        return null; // Date is before rotation started
      }
      
      // Determine which employee should work (alternating daily)
      final isEvenDay = daysSinceStart % 2 == 0;
      
      if (employee1StartsFirst) {
        return isEvenDay ? employee1Id : employee2Id;
      } else {
        return isEvenDay ? employee2Id : employee1Id;
      }
      
    } catch (e) {
      print('Error getting scheduled employee: $e');
      return null;
    }
  }
  
  /// Check if an employee is scheduled to work on a specific date
  /// 
  /// Parameters:
  /// - employeeId: Employee to check
  /// - date: Date to check
  /// 
  /// Returns: True if employee is scheduled, false otherwise
  static Future<bool> isEmployeeScheduled(String employeeId, DateTime date) async {
    final scheduledEmployee = await getScheduledEmployee(date);
    return scheduledEmployee == employeeId;
  }
  
  /// Get rotation schedule for a date range
  /// 
  /// Parameters:
  /// - startDate: Start of date range
  /// - endDate: End of date range
  /// 
  /// Returns: Map of date -> employee info
  static Future<Map<String, Map<String, dynamic>>> getRotationSchedule({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final schedule = <String, Map<String, dynamic>>{};
    
    try {
      await _ensureCacheIsValid();
      
      if (_rotationCache == null || !_rotationCache!.containsKey(_adminOfficeSection)) {
        return schedule; // No rotation configured
      }
      
      final rotation = _rotationCache![_adminOfficeSection]!;
      
      if (rotation['isActive'] != true) {
        return schedule; // Rotation is disabled
      }
      
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final scheduledEmployeeId = await getScheduledEmployee(currentDate);
        
        if (scheduledEmployeeId != null) {
          final employeeName = scheduledEmployeeId == rotation['employee1Id'] 
              ? rotation['employee1Name'] 
              : rotation['employee2Name'];
          
          schedule[DateFormat('yyyy-MM-dd').format(currentDate)] = {
            'employeeId': scheduledEmployeeId,
            'employeeName': employeeName,
            'shiftType': 'Admin Office (4PM-6PM)',
          };
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
    } catch (e) {
      print('Error getting rotation schedule: $e');
    }
    
    return schedule;
  }
  
  /// Update rotation configuration
  /// 
  /// Parameters:
  /// - isActive: Whether rotation is active
  /// - employee1StartsFirst: Whether employee1 starts first (optional)
  /// 
  /// Returns: Success status and message
  static Future<Map<String, dynamic>> updateRotation({
    bool? isActive,
    bool? employee1StartsFirst,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (isActive != null) {
        updates['isActive'] = isActive;
      }
      
      if (employee1StartsFirst != null) {
        updates['employee1StartsFirst'] = employee1StartsFirst;
      }
      
      await _firestore
          .collection(_rotationCollection)
          .doc(_adminOfficeSection)
          .update(updates);
      
      // Clear cache
      _rotationCache = null;
      
      return {
        'success': true,
        'message': 'Rotation updated successfully',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating rotation: $e',
      };
    }
  }
  
  /// Get current rotation configuration
  /// 
  /// Returns: Rotation configuration or null if not set
  static Future<Map<String, dynamic>?> getCurrentRotation() async {
    try {
      await _ensureCacheIsValid();
      return _rotationCache?[_adminOfficeSection];
    } catch (e) {
      print('Error getting current rotation: $e');
      return null;
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Validate that employees are in Admin Office section
  static Future<Map<String, dynamic>> _validateAdminOfficeEmployees(List<String> employeeIds) async {
    try {
      final employees = <String, String>{};
      
      for (final employeeId in employeeIds) {
        final doc = await _firestore.collection('Employees').doc(employeeId).get();
        
        if (!doc.exists) {
          return {
            'isValid': false,
            'message': 'Employee $employeeId not found',
          };
        }
        
        final data = doc.data()!;
        final section = data['section'] as String?;
        
        if (section?.toLowerCase() != 'admin office') {
          return {
            'isValid': false,
            'message': 'Employee ${data['name']} is not in Admin Office section',
          };
        }
        
        employees[employeeId] = data['name'] as String;
      }
      
      return {
        'isValid': true,
        'employee1Name': employees[employeeIds[0]],
        'employee2Name': employees[employeeIds[1]],
      };
      
    } catch (e) {
      return {
        'isValid': false,
        'message': 'Error validating employees: $e',
      };
    }
  }
  
  /// Ensure cache is valid and refresh if needed
  static Future<void> _ensureCacheIsValid() async {
    if (_rotationCache == null ||
        _lastCacheTime == null ||
        DateTime.now().difference(_lastCacheTime!).compareTo(_cacheValidDuration) > 0) {
      await _refreshCache();
    }
  }
  
  /// Refresh rotation cache from Firestore
  static Future<void> _refreshCache() async {
    try {
      final doc = await _firestore
          .collection(_rotationCollection)
          .doc(_adminOfficeSection)
          .get();
      
      _rotationCache = {};
      
      if (doc.exists) {
        _rotationCache![_adminOfficeSection] = doc.data()!;
      }
      
      _lastCacheTime = DateTime.now();
      
    } catch (e) {
      print('Error refreshing rotation cache: $e');
      _rotationCache = {};
    }
  }
  
  /// Clear all caches (for testing or manual refresh)
  static void clearCache() {
    _rotationCache = null;
    _lastCacheTime = null;
  }
}
