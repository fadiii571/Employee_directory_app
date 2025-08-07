import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Supervisor Attendance Service
/// 
/// Special attendance service for Supervisors section that:
/// - Uses calendar dates (9AM-9PM) instead of 4PM-4PM shift logic
/// - Stores attendance under actual calendar dates
/// - Handles 9AM-9PM work schedule
/// - Integrates with existing attendance system
class SupervisorAttendanceService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceCollection = 'attendance';
  static const String _supervisorsSection = 'Supervisors';
  
  // Supervisor work schedule
  static const String _workStartTime = '09:00'; // 9:00 AM
  static const String _workEndTime = '21:00';   // 9:00 PM
  
  // Cache for performance
  static Map<String, Map<String, dynamic>> _attendanceCache = {};
  
  // ==================== MAIN METHODS ====================
  
  /// Mark supervisor attendance (check-in or check-out)
  /// 
  /// Uses calendar date logic instead of 4PM-4PM shift logic
  /// 
  /// Parameters:
  /// - employeeId: Employee document ID
  /// - employeeName: Employee name for logging
  /// - type: 'Check In' or 'Check Out'
  /// - location: Location where attendance was marked
  /// - latitude: GPS latitude
  /// - longitude: GPS longitude
  /// 
  /// Returns: Future<Map<String, dynamic>> - Result with success status and message
  static Future<Map<String, dynamic>> markSupervisorAttendance({
    required String employeeId,
    required String employeeName,
    required String type,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final timeString = DateFormat('HH:mm').format(now);
      
      // Use calendar date (not shift date) for supervisors
      final calendarDate = DateTime(now.year, now.month, now.day);
      final dateString = DateFormat('yyyy-MM-dd').format(calendarDate);
      
      // Validate work hours for supervisors
      final validationResult = _validateSupervisorWorkHours(now, type);
      if (!validationResult['isValid']) {
        return {
          'success': false,
          'message': validationResult['message'],
        };
      }
      
      // Get or create attendance document for the calendar date
      final attendanceDoc = _firestore
          .collection(_attendanceCollection)
          .doc(dateString)
          .collection('records')
          .doc(employeeId);

      final attendanceSnapshot = await attendanceDoc.get();
      
      if (attendanceSnapshot.exists) {
        // Update existing attendance record
        await _updateExistingSupervisorAttendance(
          attendanceDoc, 
          attendanceSnapshot.data()!,
          type,
          timeString,
          location,
          latitude,
          longitude,
        );
      } else {
        // Create new attendance record
        await _createNewSupervisorAttendance(
          attendanceDoc,
          employeeId,
          employeeName,
          type,
          timeString,
          location,
          latitude,
          longitude,
          dateString,
        );
      }

      // Clear cache for this date
      _attendanceCache.remove(dateString);
      
      return {
        'success': true,
        'message': 'Supervisor attendance marked successfully at $timeString',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error marking supervisor attendance: $e',
      };
    }
  }
  
  /// Get supervisor attendance records for a date range
  /// 
  /// Parameters:
  /// - startDate: Start date for retrieval
  /// - endDate: End date for retrieval
  /// - employeeId: Optional specific employee ID
  /// 
  /// Returns: List of attendance records
  static Future<List<Map<String, dynamic>>> getSupervisorAttendanceRecords({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    final records = <Map<String, dynamic>>[];
    
    try {
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final dateString = DateFormat('yyyy-MM-dd').format(currentDate);
        
        final docRef = _firestore
            .collection(_attendanceCollection)
            .doc(dateString)
            .collection('records');
        
        QuerySnapshot snapshot;
        if (employeeId != null) {
          snapshot = await docRef.where('employeeId', isEqualTo: employeeId).get();
        } else {
          snapshot = await docRef.where('section', isEqualTo: _supervisorsSection).get();
        }
        
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['date'] = dateString;
          records.add(data);
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
    } catch (e) {
      print('Error getting supervisor attendance records: $e');
    }
    
    return records;
  }
  
  /// Get supervisor attendance summary for a date range
  /// 
  /// Parameters:
  /// - startDate: Start date for summary
  /// - endDate: End date for summary
  /// 
  /// Returns: Summary statistics
  static Future<Map<String, dynamic>> getSupervisorAttendanceSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final records = await getSupervisorAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
      );
      
      final totalDays = endDate.difference(startDate).inDays + 1;
      final presentDays = records.length;
      final absentDays = totalDays - presentDays;
      
      // Calculate punctuality (based on 9AM start time)
      int onTimeArrivals = 0;
      int lateArrivals = 0;
      
      for (final record in records) {
        final logs = List<Map<String, dynamic>>.from(record['logs'] ?? []);
        final checkInLog = logs.firstWhere(
          (log) => _isCheckInType(log['type']),
          orElse: () => <String, dynamic>{},
        );
        
        if (checkInLog.isNotEmpty) {
          final checkInTime = checkInLog['time'] as String;
          if (_isSupervisorLate(checkInTime)) {
            lateArrivals++;
          } else {
            onTimeArrivals++;
          }
        }
      }
      
      final attendanceRate = totalDays > 0 ? (presentDays / totalDays) * 100 : 0.0;
      final punctualityRate = presentDays > 0 ? (onTimeArrivals / presentDays) * 100 : 0.0;
      
      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'attendanceRate': attendanceRate,
        'punctualityRate': punctualityRate,
        'onTimeArrivals': onTimeArrivals,
        'lateArrivals': lateArrivals,
      };
      
    } catch (e) {
      return {
        'totalDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'attendanceRate': 0.0,
        'punctualityRate': 0.0,
        'onTimeArrivals': 0,
        'lateArrivals': 0,
      };
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Validate supervisor work hours
  static Map<String, dynamic> _validateSupervisorWorkHours(DateTime now, String type) {
    final hour = now.hour;
    
    // Allow check-in from 8:30 AM (30 minutes early) to 10:00 AM (1 hour late)
    if (type == 'Check In') {
      if (hour < 8 || hour > 10) {
        return {
          'isValid': false,
          'message': 'Check-in allowed between 8:30 AM and 10:00 AM only',
        };
      }
    }
    
    // Allow check-out from 8:00 PM to 10:00 PM (flexible checkout)
    if (type == 'Check Out') {
      if (hour < 20 || hour > 22) {
        return {
          'isValid': false,
          'message': 'Check-out allowed between 8:00 PM and 10:00 PM only',
        };
      }
    }
    
    return {'isValid': true};
  }
  
  /// Check if supervisor is late (after 9:00 AM)
  static bool _isSupervisorLate(String checkInTime) {
    try {
      final time = DateFormat('HH:mm').parse(checkInTime);
      final nineAM = DateFormat('HH:mm').parse('09:00');
      return time.isAfter(nineAM);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if the attendance type represents a check-in
  static bool _isCheckInType(dynamic type) {
    if (type == null) return false;
    final typeStr = type.toString().toLowerCase().trim();
    return typeStr == 'check in' || typeStr == 'in' || typeStr == 'checkin';
  }
  
  /// Update existing supervisor attendance record
  static Future<void> _updateExistingSupervisorAttendance(
    DocumentReference attendanceDoc,
    Map<String, dynamic> existingData,
    String type,
    String timeString,
    String location,
    double latitude,
    double longitude,
  ) async {
    final logs = List<Map<String, dynamic>>.from(existingData['logs'] ?? []);
    
    // Add new log entry
    logs.add({
      'type': type,
      'time': timeString,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await attendanceDoc.update({
      'logs': logs,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  /// Create new supervisor attendance record
  static Future<void> _createNewSupervisorAttendance(
    DocumentReference attendanceDoc,
    String employeeId,
    String employeeName,
    String type,
    String timeString,
    String location,
    double latitude,
    double longitude,
    String dateString,
  ) async {
    await attendanceDoc.set({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'section': _supervisorsSection,
      'workDate': dateString, // Calendar date, not shift date
      'workSchedule': '9AM-9PM',
      'logs': [
        {
          'type': type,
          'time': timeString,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ],
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
  
  /// Clear all caches (for testing or manual refresh)
  static void clearCache() {
    _attendanceCache.clear();
  }
}
