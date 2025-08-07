import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../model/kpi_models.dart';
import 'section_shift_service.dart';

/// KPI (Key Performance Indicators) Service
/// 
/// This service handles all KPI-related calculations:
/// - Section-aware punctuality calculations
/// - Employee attendance KPIs
/// - Section-wise performance summaries
/// - Caching for performance optimization
/// - Parallel processing for efficiency
/// 
/// Key Features:
/// - Uses section shift configurations for accurate punctuality
/// - Calculates early arrivals, on-time arrivals, and late arrivals
/// - Provides both individual and section-level KPIs
/// - Optimized with caching and batch processing
class KPIService {
  
  // ==================== CONSTANTS ====================
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceCollection = 'attendance';
  static const String _employeesCollection = 'Employees';
  static const String _paidLeaveCollection = 'paid_leave';

  // ==================== CACHE MANAGEMENT ====================
  
  /// Cache for KPI data to improve performance
  static final Map<String, Map<String, dynamic>> _kpiCache = {};
  static final Map<String, Map<String, dynamic>> _employeeCache = {};
  
  /// Cache validity duration
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  /// Clear all caches
  static void clearCache() {
    _kpiCache.clear();
    _employeeCache.clear();
  }

  // ==================== EMPLOYEE KPI CALCULATIONS ====================
  
  /// Calculate attendance KPI for a specific employee
  /// 
  /// This function calculates comprehensive KPI metrics for an employee
  /// including attendance rate, punctuality rate, and early arrival rate.
  /// 
  /// Parameters:
  /// - employeeId: Employee document ID
  /// - startDate: Start date for KPI calculation period
  /// - endDate: End date for KPI calculation period
  /// 
  /// Returns: Future<AttendanceKPI> - Complete KPI data for the employee
  static Future<AttendanceKPI> calculateEmployeeAttendanceKPI({
    required String employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get employee details from cache or Firestore
      final empData = await _getEmployeeData(employeeId);
      final employeeName = empData['name'] ?? 'Unknown';
      final section = empData['section'] ?? 'Unknown';

      // Get section shift configuration
      final sectionShift = await SectionShiftService.getSectionShift(section);

      // Calculate shift dates using consistent 4PM-4PM logic
      final shiftDates = _generateShiftAwareDateList(startDate, endDate);
      
      // Get paid leave data for the period
      final paidLeaveData = await _getBatchPaidLeaveData(employeeId, startDate, endDate);

      // Initialize counters
      int totalWorkingDays = shiftDates.length;
      int presentDays = 0;
      int absentDays = 0;
      int lateArrivals = 0;
      int onTimeArrivals = 0;
      int earlyArrivals = 0;

      // Process each shift date
      for (final shiftDate in shiftDates) {
        final attendanceRecord = await _getAttendanceRecord(employeeId, shiftDate);

        if (attendanceRecord != null) {
          final logs = List<Map<String, dynamic>>.from(attendanceRecord['logs'] ?? []);

          // Find check-in log - handle different type formats
          final checkInLog = logs.firstWhere(
            (log) => _isCheckInType(log['type']),
            orElse: () => <String, dynamic>{},
          );

          if (checkInLog.isNotEmpty) {
            presentDays++;

            // Check punctuality based on section shift configuration
            final checkInTime = checkInLog['time'] as String;

            // Parse time to handle different formats (HH:mm vs hh:mm a)
            final parsedCheckInTime = _parseAttendanceTime(checkInTime);

            if (SectionShiftService.isEmployeeLate(parsedCheckInTime, sectionShift)) {
              lateArrivals++;
            } else {
              onTimeArrivals++;

              // Check if employee arrived early (bonus point)
              if (SectionShiftService.isEmployeeEarly(parsedCheckInTime, sectionShift)) {
                earlyArrivals++;
              }
            }
          }
        } else {
          // Check for paid leave
          final dateString = DateFormat('yyyy-MM-dd').format(shiftDate);
          if (!paidLeaveData.contains(dateString)) {
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

    } catch (e) {
      // Return default KPI on error
      return AttendanceKPI(
        employeeId: employeeId,
        employeeName: 'Unknown',
        section: 'Unknown',
        attendanceRate: 0.0,
        punctualityRate: 0.0,
        earlyArrivalRate: 0.0,
        totalWorkingDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateArrivals: 0,
        onTimeArrivals: 0,
        earlyArrivals: 0,
        calculationPeriodStart: startDate,
        calculationPeriodEnd: endDate,
        sectionShift: SectionShift(
          sectionName: 'Unknown',
          checkInTime: '09:00',
          gracePeriodMinutes: 0,
        ),
      );
    }
  }

  // ==================== SECTION KPI CALCULATIONS ====================
  
  /// Calculate section-wise attendance summary
  /// 
  /// This function calculates KPI metrics for an entire section
  /// by processing all employees in parallel for better performance.
  /// 
  /// Parameters:
  /// - sectionName: Name of the section
  /// - startDate: Start date for calculation period
  /// - endDate: End date for calculation period
  /// 
  /// Returns: Future<SectionAttendanceSummary> - Section-level KPI data
  static Future<SectionAttendanceSummary> calculateSectionAttendanceSummary({
    required String sectionName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Get section shift configuration
      final sectionShift = await SectionShiftService.getSectionShift(sectionName);

      // Get all employees in the section
      final employeeSnapshot = await _firestore
          .collection(_employeesCollection)
          .where('section', isEqualTo: sectionName)
          .where('isActive', isEqualTo: true)
          .get();

      if (employeeSnapshot.docs.isEmpty) {
        return _createEmptySectionSummary(sectionName, sectionShift, startDate, endDate);
      }

      // Calculate all employee KPIs in parallel for better performance
      final futures = employeeSnapshot.docs.map((empDoc) =>
        calculateEmployeeAttendanceKPI(
          employeeId: empDoc.id,
          startDate: startDate,
          endDate: endDate,
        )
      );

      final employeeKPIs = await Future.wait(futures);

      // Aggregate section-level metrics
      double totalAttendanceRate = 0.0;
      double totalPunctualityRate = 0.0;
      double totalEarlyArrivalRate = 0.0;
      int totalPresentDays = 0;
      int totalAbsentDays = 0;
      int totalLateArrivals = 0;
      int totalOnTimeArrivals = 0;
      int totalEarlyArrivals = 0;
      int activeEmployees = 0;

      for (final empKPI in employeeKPIs) {
        if (empKPI.presentDays > 0) {
          activeEmployees++;
          totalAttendanceRate += empKPI.attendanceRate;
          totalPunctualityRate += empKPI.punctualityRate;
          totalEarlyArrivalRate += empKPI.earlyArrivalRate;
        }
        
        totalPresentDays += empKPI.presentDays;
        totalAbsentDays += empKPI.absentDays;
        totalLateArrivals += empKPI.lateArrivals;
        totalOnTimeArrivals += empKPI.onTimeArrivals;
        totalEarlyArrivals += empKPI.earlyArrivals;
      }

      // Calculate average rates
      final avgAttendanceRate = activeEmployees > 0 ? totalAttendanceRate / activeEmployees : 0.0;
      final avgPunctualityRate = activeEmployees > 0 ? totalPunctualityRate / activeEmployees : 0.0;
      final avgEarlyArrivalRate = activeEmployees > 0 ? totalEarlyArrivalRate / activeEmployees : 0.0;

      return SectionAttendanceSummary(
        sectionName: sectionName,
        sectionShift: sectionShift,
        sectionAttendanceRate: avgAttendanceRate,
        sectionPunctualityRate: avgPunctualityRate,
        sectionEarlyArrivalRate: avgEarlyArrivalRate,
        totalEmployees: employeeSnapshot.docs.length,
        presentEmployees: activeEmployees,
        employeeKPIs: employeeKPIs,
        calculationPeriodStart: startDate,
        calculationPeriodEnd: endDate,
      );

    } catch (e) {
      final defaultShift = SectionShift(
        sectionName: sectionName,
        checkInTime: '09:00',
        gracePeriodMinutes: 0
      );
      return _createEmptySectionSummary(sectionName, defaultShift, startDate, endDate);
    }
  }

  // ==================== BATCH KPI OPERATIONS ====================
  
  /// Get KPI data with caching and optimization
  /// 
  /// This function provides a unified interface for getting KPI data
  /// with automatic caching and performance optimizations.
  /// 
  /// Parameters:
  /// - filter: KPIFilter object specifying what data to retrieve
  /// 
  /// Returns: Future with Map containing KPI data and type information
  static Future<Map<String, dynamic>> getAttendanceKPIData(KPIFilter filter) async {
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
      // All sections KPI - calculate in parallel for better performance
      const sections = ['Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering', 'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'];

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

  // ==================== HELPER METHODS ====================

  /// Check if the attendance type represents a check-in
  /// Handles different formats: "Check In", "In", "check in", etc.
  static bool _isCheckInType(dynamic type) {
    if (type == null) return false;
    final typeStr = type.toString().toLowerCase().trim();
    return typeStr == 'check in' || typeStr == 'in' || typeStr == 'checkin';
  }

  /// Parse attendance time to handle different formats
  /// Converts "hh:mm a" format to "HH:mm" format for consistency
  static String _parseAttendanceTime(String timeString) {
    try {
      // If already in HH:mm format, return as is
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(timeString)) {
        return timeString;
      }

      // If in hh:mm a format, convert to HH:mm
      if (timeString.toLowerCase().contains('am') || timeString.toLowerCase().contains('pm')) {
        final dateTime = DateFormat('hh:mm a').parse(timeString);
        return DateFormat('HH:mm').format(dateTime);
      }

      // If in h:mm a format, convert to HH:mm
      if (timeString.contains(':') && (timeString.toLowerCase().contains('am') || timeString.toLowerCase().contains('pm'))) {
        final dateTime = DateFormat('h:mm a').parse(timeString);
        return DateFormat('HH:mm').format(dateTime);
      }

      // Return original if can't parse
      return timeString;
    } catch (e) {
      // Return original string if parsing fails
      return timeString;
    }
  }

  /// Get employee data from cache or Firestore
  static Future<Map<String, dynamic>> _getEmployeeData(String employeeId) async {
    if (_employeeCache.containsKey(employeeId)) {
      return _employeeCache[employeeId]!;
    }

    final empDoc = await _firestore.collection(_employeesCollection).doc(employeeId).get();
    final empData = empDoc.data() ?? {};
    _employeeCache[employeeId] = empData;
    return empData;
  }

  /// Generate shift-aware date list for attendance lookup
  static List<DateTime> _generateShiftAwareDateList(DateTime startDate, DateTime endDate) {
    final List<DateTime> dates = [];
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Get attendance record for a specific employee and date
  static Future<Map<String, dynamic>?> _getAttendanceRecord(String employeeId, DateTime date) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final doc = await _firestore
          .collection(_attendanceCollection)
          .doc(dateString)
          .collection('records')
          .doc(employeeId)
          .get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  /// Get paid leave data for an employee in a date range
  static Future<Set<String>> _getBatchPaidLeaveData(String employeeId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection(_paidLeaveCollection)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return snapshot.docs.map((doc) {
        final timestamp = doc.data()['date'] as Timestamp;
        return DateFormat('yyyy-MM-dd').format(timestamp.toDate());
      }).toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Create empty section summary for error cases
  static SectionAttendanceSummary _createEmptySectionSummary(
    String sectionName,
    SectionShift sectionShift,
    DateTime startDate,
    DateTime endDate,
  ) {
    return SectionAttendanceSummary(
      sectionName: sectionName,
      sectionShift: sectionShift,
      sectionAttendanceRate: 0.0,
      sectionPunctualityRate: 0.0,
      sectionEarlyArrivalRate: 0.0,
      totalEmployees: 0,
      presentEmployees: 0,
      employeeKPIs: [],
      calculationPeriodStart: startDate,
      calculationPeriodEnd: endDate,
    );
  }
}
