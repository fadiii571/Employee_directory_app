import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/kpi_models.dart';

/// Service for managing section-specific shift configurations
///
/// This service handles:
/// - Check-in times for different sections
/// - Grace periods for punctuality calculations
/// - KPI-related shift logic
/// - Caching for performance optimization
///
/// Section Types:
/// - Hardcoded: Admin Office (4PM check-in, fully managed in markQRAttendance)
/// - Configurable: All other sections (admin can set check-in time and grace period)
/// - Extended Checkout: Fancy & KK (configurable check-in, but 6PM checkout in markQRAttendance)
class SectionShiftService {

  // ==================== CONSTANTS & CONFIGURATION ====================

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // ==================== CACHE MANAGEMENT ====================

  /// Cache for loaded shifts from Firestore (performance optimization)
  static Map<String, SectionShift>? _cachedShifts;
  static DateTime? _lastCacheTime;

  // ==================== DEFAULT CONFIGURATIONS ====================

  /// Default shift configurations for all sections
  /// These serve as fallbacks when no custom configuration exists
  static final Map<String, SectionShift> _defaultShifts = {
    'Fancy': SectionShift(
      sectionName: 'Fancy',
      checkInTime: '05:30', // Default 5:30 AM (configurable)
      gracePeriodMinutes: 10, // Default 10-minute grace (configurable)
    ),
    'KK': SectionShift(
      sectionName: 'KK',
      checkInTime: '05:30', // Default 5:30 AM (configurable)
      gracePeriodMinutes: 10, // Default 10-minute grace (configurable)
    ),
    'Anchor': SectionShift(
      sectionName: 'Anchor',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Soldering': SectionShift(
      sectionName: 'Soldering',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Wire': SectionShift(
      sectionName: 'Wire',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Joint': SectionShift(
      sectionName: 'Joint',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'V chain': SectionShift(
      sectionName: 'V chain',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Cutting': SectionShift(
      sectionName: 'Cutting',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Box chain': SectionShift(
      sectionName: 'Box chain',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Polish': SectionShift(
      sectionName: 'Polish',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
    'Supervisors': SectionShift(
      sectionName: 'Supervisors',
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    ),
  };

  // ==================== PUBLIC API METHODS ====================

  /// Get shift configuration for a section
  ///
  /// This is the main method used by KPI calculations to get section-specific
  /// check-in times and grace periods.
  ///
  /// Returns:
  /// - Admin Office: Hardcoded 4PM check-in (managed in markQRAttendance)
  /// - Other sections: Configurable check-in time from Firestore or defaults
  ///
  /// Uses caching for performance - cache refreshes every 5 minutes
  static Future<SectionShift> getSectionShift(String sectionName) async {
    // Handle fully hardcoded sections (Admin Office only)
    if (_isHardcodedSection(sectionName)) {
      return _getHardcodedShift(sectionName);
    }

    // Handle configurable sections (including Fancy and KK)
    await _ensureCacheIsValid();
    return _getConfigurableShift(sectionName);
  }

  /// Get shift configuration synchronously (for backward compatibility)
  /// This method tries to use cached data but falls back to defaults if cache is empty
  static SectionShift getSectionShiftSync(String sectionName) {
    // Handle only fully hardcoded sections (Admin Office only)
    if (_isHardcodedSection(sectionName)) {
      // Admin Office uses 4PM check-in time
      return SectionShift(
        sectionName: sectionName,
        checkInTime: '16:00', // 4PM hardcoded shift start
        gracePeriodMinutes: 0,
      );
    }

    // All other sections (including Fancy and KK) are now configurable
    // If we have cached data, use it
    if (_cachedShifts != null && _cachedShifts!.containsKey(sectionName)) {
      return _cachedShifts![sectionName]!;
    }

    // Otherwise, use default shifts (which might be updated)
    return _defaultShifts[sectionName] ?? SectionShift(
      sectionName: sectionName,
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Check if section has fully hardcoded shift logic in markQRAttendance
  /// Only Admin Office is fully hardcoded - Fancy and KK are now configurable
  static bool _isHardcodedSection(String sectionName) {
    final sectionLower = sectionName.toLowerCase();
    return sectionLower == 'admin office';
  }

  /// Get hardcoded shift configuration (Admin Office only)
  static SectionShift _getHardcodedShift(String sectionName) {
    return SectionShift(
      sectionName: sectionName,
      checkInTime: '16:00', // 4PM hardcoded shift start
      gracePeriodMinutes: 0,
    );
  }

  /// Ensure cache is valid and refresh if needed
  static Future<void> _ensureCacheIsValid() async {
    if (_cachedShifts == null ||
        _lastCacheTime == null ||
        DateTime.now().difference(_lastCacheTime!).compareTo(_cacheValidDuration) > 0) {
      await _refreshCache();
    }
  }

  /// Get configurable shift from cache or defaults
  static SectionShift _getConfigurableShift(String sectionName) {
    return _cachedShifts![sectionName] ?? SectionShift(
      sectionName: sectionName,
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
    );
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Refresh cache from Firestore
  /// This method loads all section shifts from Firestore and updates the cache
  static Future<void> _refreshCache() async {
    try {
      _cachedShifts = await loadSectionShiftsFromFirestore();
      _lastCacheTime = DateTime.now();
    } catch (e) {
      // If loading fails, use default shifts as fallback
      _cachedShifts = Map.from(_defaultShifts);
      _lastCacheTime = DateTime.now();
    }
  }

  /// Initialize the service by loading shifts from Firestore
  /// Call this once when the app starts to populate the cache
  static Future<void> initialize() async {
    await _refreshCache();
  }

  /// Get all section shifts with automatic cache management
  /// Returns cached data if valid, otherwise refreshes from Firestore
  static Future<Map<String, SectionShift>> getAllSectionShifts() async {
    await _ensureCacheIsValid();
    return Map.from(_cachedShifts!);
  }

  /// Get all section shifts synchronously (for backward compatibility)
  /// Uses cached data if available, otherwise returns defaults
  static Map<String, SectionShift> getAllSectionShiftsSync() {
    return _cachedShifts != null ? Map.from(_cachedShifts!) : Map.from(_defaultShifts);
  }

  // ==================== DATA PERSISTENCE METHODS ====================

  /// Save a single section shift configuration to Firestore
  static Future<void> saveSectionShift(SectionShift shift) async {
    await _firestore
        .collection('section_shifts')
        .doc(shift.sectionName)
        .set(shift.toJson());
  }

  /// Load all section shifts from Firestore
  /// Returns default shifts if Firestore is empty or fails
  static Future<Map<String, SectionShift>> loadSectionShiftsFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('section_shifts').get();
      final Map<String, SectionShift> shifts = {};

      // Parse each document into SectionShift object
      for (final doc in snapshot.docs) {
        final shift = SectionShift.fromJson(doc.data());
        shifts[shift.sectionName] = shift;
      }

      // If no shifts found in Firestore, initialize with defaults
      if (shifts.isEmpty) {
        await saveDefaultShiftsToFirestore();
        return Map.from(_defaultShifts);
      }

      return shifts;
    } catch (e) {
      // Return defaults if loading fails
      return Map.from(_defaultShifts);
    }
  }

  /// Save all default shifts to Firestore (initialization)
  static Future<void> saveDefaultShiftsToFirestore() async {
    for (final shift in _defaultShifts.values) {
      await saveSectionShift(shift);
    }
  }

  /// Update a section's shift configuration
  /// This is the main method used by the admin interface
  static Future<void> updateSectionShift({
    required String sectionName,
    required String checkInTime,
    int gracePeriodMinutes = 0,
  }) async {
    final shift = SectionShift(
      sectionName: sectionName,
      checkInTime: checkInTime,
      gracePeriodMinutes: gracePeriodMinutes,
    );

    // Save to Firestore
    await saveSectionShift(shift);

    // Update local defaults
    _defaultShifts[sectionName] = shift;

    // Force cache refresh to ensure immediate effect
    _cachedShifts = null;
    _lastCacheTime = null;
    await _refreshCache();
  }

  // ==================== PUNCTUALITY CALCULATION METHODS ====================

  /// Check if employee is late based on section shift check-in time
  ///
  /// Logic:
  /// - Parse employee's actual check-in time
  /// - Compare with section's expected check-in time + grace period
  /// - Return true if employee checked in after the allowed time
  static bool isEmployeeLate(String checkInTime, SectionShift shift) {
    try {
      final checkIn = _parseTime(checkInTime);
      final expectedCheckIn = _parseTime(shift.checkInTime);
      final allowedCheckIn = expectedCheckIn.add(Duration(minutes: shift.gracePeriodMinutes));

      return checkIn.isAfter(allowedCheckIn);
    } catch (e) {
      return false; // If parsing fails, assume not late
    }
  }

  /// Check if employee arrived early (bonus for KPI)
  ///
  /// Logic:
  /// - Consider early if arrived 15+ minutes before expected check-in time
  /// - This gives bonus points in KPI calculations
  static bool isEmployeeEarly(String checkInTime, SectionShift shift) {
    try {
      final checkIn = _parseTime(checkInTime);
      final expectedCheckIn = _parseTime(shift.checkInTime);
      final earlyThreshold = expectedCheckIn.subtract(const Duration(minutes: 15));

      return checkIn.isBefore(earlyThreshold);
    } catch (e) {
      return false;
    }
  }

  /// Check if employee is on time (not late and not early)
  static bool isEmployeeOnTime(String checkInTime, SectionShift shift) {
    return !isEmployeeLate(checkInTime, shift) && !isEmployeeEarly(checkInTime, shift);
  }

  // ==================== UTILITY METHODS ====================

  /// Get shift duration in hours (display purposes only)
  /// Since we only track check-in time, return standard 8-hour duration
  static double getShiftDurationHours(SectionShift shift) {
    return 8.0; // Standard duration for display
  }

  /// Get formatted shift time display for UI
  static String getShiftTimeDisplay(SectionShift shift) {
    final gracePeriod = shift.gracePeriodMinutes > 0
        ? ' (${shift.gracePeriodMinutes}min grace)'
        : '';
    return 'Check-in: ${shift.checkInTime}$gracePeriod';
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Parse time string (HH:mm) into DateTime object
  /// Used for time comparisons in punctuality calculations
  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // ==================== DEBUG METHODS (DEVELOPMENT ONLY) ====================

  /// DEBUG: Test function to check if Joint section config is properly saved/loaded
  /// This method helps verify that section shift configurations are working correctly
  static Future<void> debugJointSectionConfig() async {
    print('🔍 DEBUG: Testing Joint section configuration...');

    // Force refresh cache
    await _refreshCache();

    // Get Joint section config
    final jointShift = await getSectionShift('Joint');
    print('📊 Joint Section Config:');
    print('  - Check-in Time: ${jointShift.checkInTime}');
    print('  - Grace Period: ${jointShift.gracePeriodMinutes} minutes');

    // Check Firestore directly
    try {
      final doc = await _firestore.collection('section_shifts').doc('Joint').get();
      if (doc.exists) {
        final data = doc.data()!;
        print('🔥 Firestore Data for Joint:');
        print('  - Check-in Time: ${data['checkInTime']}');
        print('  - Grace Period: ${data['gracePeriodMinutes']}');
      } else {
        print('❌ No Joint section data found in Firestore');
      }
    } catch (e) {
      print('❌ Error reading from Firestore: $e');
    }

    // Test punctuality calculation for 2:55 check-in
    final isLate = isEmployeeLate('02:55', jointShift);
    final isEarly = isEmployeeEarly('02:55', jointShift);
    final isOnTime = isEmployeeOnTime('02:55', jointShift);

    print('⏰ Punctuality Test for 2:55 check-in:');
    print('  - Is Late: $isLate');
    print('  - Is Early: $isEarly');
    print('  - Is On Time: $isOnTime');

    if (isEarly) {
      print('✅ Result: EARLY');
    } else if (isOnTime) {
      print('✅ Result: ON TIME');
    } else {
      print('❌ Result: LATE');
    }
  }
}
