import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'supervisor_attendance_service.dart';


/// Attendance Management Service
/// 
/// This service handles all attendance-related operations:
/// - QR code-based check-in/check-out
/// - Shift-aware attendance storage (4PM-4PM logic)
/// - Extended checkout rules for special sections
/// - Attendance history retrieval
/// - Performance optimizations with caching
/// 
/// Key Features:
/// - Admin Office, Fancy, KK: 4PM-4PM shifts with extended checkout until 6PM
/// - Other sections: Standard 4PM-4PM shifts
/// - Attendance stored under shift start date for consistency
class AttendanceService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceCollection = 'attendance';
  
  /// Sections with extended checkout until 6PM next day
  static const List<String> extendedCheckoutSections = ['Admin office', 'Fancy', 'KK'];

  // ==================== CACHE MANAGEMENT ====================
  
  /// Cache for attendance data to improve performance
  static final Map<String, Map<String, dynamic>> _attendanceCache = {};
  
  /// Clear the attendance cache
  static void clearCache() {
    _attendanceCache.clear();
  }

  // ==================== QR ATTENDANCE OPERATIONS ====================
  
  /// Mark QR attendance (check-in or check-out)
  /// 
  /// This is the main function for processing QR code scans.
  /// It handles shift-aware storage and extended checkout rules.
  /// 
  /// Parameters:
  /// - employeeId: Employee document ID
  /// - employeeName: Employee name for logging
  /// - section: Employee's work section
  /// - type: 'Check In' or 'Check Out'
  /// - location: Location where attendance was marked
  /// - latitude: GPS latitude
  /// - longitude: GPS longitude
  /// 
  /// Returns: Future<Map<String, dynamic>> - Result with success status and message
  static Future<Map<String, dynamic>> markQRAttendance({
    required String employeeId,
    required String employeeName,
    required String section,
    required String type,
    required String location,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Handle Supervisors section differently (9AM-9PM calendar dates)
      if (section.toLowerCase() == 'supervisors') {
        return await SupervisorAttendanceService.markSupervisorAttendance(
          employeeId: employeeId,
          employeeName: employeeName,
          type: type,
          location: location,
          latitude: latitude,
          longitude: longitude,
        );
      }

      final now = DateTime.now();
      final timeString = DateFormat('HH:mm').format(now);

      // Calculate shift date using 4PM-4PM logic for non-supervisor sections
      final shiftDate = _calculateShiftDate(now, section);
      final shiftDateString = DateFormat('yyyy-MM-dd').format(shiftDate);
      
      // Validate checkout timing for extended sections
      if (type == 'Check Out' && extendedCheckoutSections.contains(section)) {
        final validationResult = _validateExtendedCheckout(now, section);
        if (!validationResult['isValid']) {
          return {
            'success': false,
            'message': validationResult['message'],
          };
        }
      }

      // Get or create attendance document for the shift date
      final attendanceDoc = _firestore
          .collection(_attendanceCollection)
          .doc(shiftDateString)
          .collection('records')
          .doc(employeeId);

      final attendanceSnapshot = await attendanceDoc.get();
      
      if (attendanceSnapshot.exists) {
        // Update existing attendance record
        await _updateExistingAttendance(
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
        await _createNewAttendance(
          attendanceDoc,
          employeeId,
          employeeName,
          section,
          type,
          timeString,
          location,
          latitude,
          longitude,
          shiftDateString,
        );
      }

      // Clear cache for this date
      _attendanceCache.remove(shiftDateString);

      return {
        'success': true,
        'message': '$type marked successfully for $employeeName',
        'shiftDate': shiftDateString,
        'time': timeString,
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Error marking attendance: ${e.toString()}',
      };
    }
  }

  /// Get attendance records for a specific date range
  /// 
  /// Parameters:
  /// - startDate: Start date for the range
  /// - endDate: End date for the range
  /// - section: Optional section filter
  /// 
  /// Returns: Future<List<Map<String, dynamic>>> - List of attendance records
  static Future<List<Map<String, dynamic>>> getAttendanceRecords({
    required DateTime startDate,
    required DateTime endDate,
    String? section,
  }) async {
    try {
      final List<Map<String, dynamic>> allRecords = [];
      
      // Generate list of dates to query
      final dates = _generateDateList(startDate, endDate);
      
      for (final date in dates) {
        final dateString = DateFormat('yyyy-MM-dd').format(date);
        
        // Check cache first
        if (_attendanceCache.containsKey(dateString)) {
          final cachedData = _attendanceCache[dateString]!;
          if (section == null || cachedData['section'] == section) {
            allRecords.add(cachedData);
          }
          continue;
        }

        // Query Firestore
        Query query = _firestore
            .collection(_attendanceCollection)
            .doc(dateString)
            .collection('records');

        if (section != null) {
          query = query.where('section', isEqualTo: section);
        }

        final snapshot = await query.get();
        
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['date'] = dateString;
          
          // Cache the record
          _attendanceCache['${dateString}_${doc.id}'] = data;
          
          allRecords.add(data);
        }
      }

      return allRecords;
    } catch (e) {
      return [];
    }
  }

  /// Get attendance for a specific employee and date
  /// 
  /// Parameters:
  /// - employeeId: Employee document ID
  /// - date: Date to get attendance for
  /// 
  /// Returns: Future<Map<String, dynamic>?> - Attendance record or null
  static Future<Map<String, dynamic>?> getEmployeeAttendance({
    required String employeeId,
    required DateTime date,
  }) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final cacheKey = '${dateString}_$employeeId';
      
      // Check cache first
      if (_attendanceCache.containsKey(cacheKey)) {
        return _attendanceCache[cacheKey];
      }

      // Query Firestore
      final doc = await _firestore
          .collection(_attendanceCollection)
          .doc(dateString)
          .collection('records')
          .doc(employeeId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['date'] = dateString;
        
        // Cache the result
        _attendanceCache[cacheKey] = data;
        
        return data;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== HELPER METHODS ====================
  
  /// Calculate shift date using 4PM-4PM logic
  /// 
  /// Logic:
  /// - Before 4PM: Previous day's shift
  /// - 4PM or after: Current day's shift
  /// - Extended sections can checkout until 6PM next day but stored under shift start date
  static DateTime _calculateShiftDate(DateTime dateTime, String section) {
    if (dateTime.hour < 16) {
      // Before 4PM = previous day's shift
      return DateTime(dateTime.year, dateTime.month, dateTime.day - 1, 16);
    } else {
      // 4PM or after = current day's shift
      return DateTime(dateTime.year, dateTime.month, dateTime.day, 16);
    }
  }

  /// Validate extended checkout timing
  /// 
  /// Extended sections (Admin Office, Fancy, KK) can checkout until 6PM next day
  static Map<String, dynamic> _validateExtendedCheckout(DateTime now, String section) {
    if (!extendedCheckoutSections.contains(section)) {
      return {'isValid': true};
    }

    // For extended sections, allow checkout until 6PM next day
    final currentShiftStart = _calculateShiftDate(now, section);
    final maxCheckoutTime = currentShiftStart.add(const Duration(hours: 26)); // 4PM + 26 hours = 6PM next day

    if (now.isAfter(maxCheckoutTime)) {
      return {
        'isValid': false,
        'message': 'Checkout time exceeded. Maximum checkout time is 6PM next day.',
      };
    }

    return {'isValid': true};
  }

  /// Update existing attendance record
  static Future<void> _updateExistingAttendance(
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

  /// Create new attendance record
  static Future<void> _createNewAttendance(
    DocumentReference attendanceDoc,
    String employeeId,
    String employeeName,
    String section,
    String type,
    String timeString,
    String location,
    double latitude,
    double longitude,
    String shiftDateString,
  ) async {
    await attendanceDoc.set({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'section': section,
      'shiftDate': shiftDateString,
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

  /// Generate list of dates between start and end date
  static List<DateTime> _generateDateList(DateTime startDate, DateTime endDate) {
    final List<DateTime> dates = [];
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get attendance summary for a date range
  /// 
  /// Returns summary statistics for attendance in the given period
  static Future<Map<String, dynamic>> getAttendanceSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? section,
  }) async {
    try {
      final records = await getAttendanceRecords(
        startDate: startDate,
        endDate: endDate,
        section: section,
      );

      int totalEmployees = 0;
      int presentDays = 0;
      int totalCheckIns = 0;
      int totalCheckOuts = 0;
      final Set<String> uniqueEmployees = {};

      for (final record in records) {
        uniqueEmployees.add(record['employeeId']);
        
        final logs = List<Map<String, dynamic>>.from(record['logs'] ?? []);
        bool hasCheckIn = false;
        bool hasCheckOut = false;

        for (final log in logs) {
          if (log['type'] == 'Check In') {
            totalCheckIns++;
            hasCheckIn = true;
          } else if (log['type'] == 'Check Out') {
            totalCheckOuts++;
            hasCheckOut = true;
          }
        }

        if (hasCheckIn) {
          presentDays++;
        }
      }

      totalEmployees = uniqueEmployees.length;

      return {
        'totalEmployees': totalEmployees,
        'presentDays': presentDays,
        'totalCheckIns': totalCheckIns,
        'totalCheckOuts': totalCheckOuts,
        'attendanceRate': totalEmployees > 0 ? (presentDays / totalEmployees) * 100 : 0.0,
      };
    } catch (e) {
      return {
        'totalEmployees': 0,
        'presentDays': 0,
        'totalCheckIns': 0,
        'totalCheckOuts': 0,
        'attendanceRate': 0.0,
        'error': e.toString(),
      };
    }
  }
}
