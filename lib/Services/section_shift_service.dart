import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/kpi_models.dart';

class SectionShiftService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default section shifts - these will be empty initially for manual configuration
  static Map<String, SectionShift> _defaultShifts = {
    'Admin office': SectionShift(
      sectionName: 'Admin office',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Anchor': SectionShift(
      sectionName: 'Anchor',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Fancy': SectionShift(
      sectionName: 'Fancy',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'KK': SectionShift(
      sectionName: 'KK',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Soldering': SectionShift(
      sectionName: 'Soldering',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Wire': SectionShift(
      sectionName: 'Wire',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Joint': SectionShift(
      sectionName: 'Joint',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'V chain': SectionShift(
      sectionName: 'V chain',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Cutting': SectionShift(
      sectionName: 'Cutting',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Box chain': SectionShift(
      sectionName: 'Box chain',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
    'Polish': SectionShift(
      sectionName: 'Polish',
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    ),
  };

  /// Get shift configuration for a section
  static SectionShift getSectionShift(String sectionName) {
    return _defaultShifts[sectionName] ?? SectionShift(
      sectionName: sectionName,
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    );
  }

  /// Get all section shifts
  static Map<String, SectionShift> getAllSectionShifts() {
    return Map.from(_defaultShifts);
  }

  /// Save section shift configuration to Firestore
  static Future<void> saveSectionShift(SectionShift shift) async {
    await _firestore
        .collection('section_shifts')
        .doc(shift.sectionName)
        .set(shift.toJson());
  }

  /// Load section shifts from Firestore
  static Future<Map<String, SectionShift>> loadSectionShiftsFromFirestore() async {
    try {
      final snapshot = await _firestore.collection('section_shifts').get();
      final Map<String, SectionShift> shifts = {};
      
      for (final doc in snapshot.docs) {
        final shift = SectionShift.fromJson(doc.data());
        shifts[shift.sectionName] = shift;
      }
      
      // If no shifts found in Firestore, save default shifts
      if (shifts.isEmpty) {
        await saveDefaultShiftsToFirestore();
        return _defaultShifts;
      }
      
      return shifts;
    } catch (e) {
      print('Error loading section shifts: $e');
      return _defaultShifts;
    }
  }

  /// Save default shifts to Firestore
  static Future<void> saveDefaultShiftsToFirestore() async {
    for (final shift in _defaultShifts.values) {
      await saveSectionShift(shift);
    }
  }

  /// Update section shift
  static Future<void> updateSectionShift({
    required String sectionName,
    required String startTime,
    required String endTime,
    required bool isOvernightShift,
  }) async {
    final shift = SectionShift(
      sectionName: sectionName,
      startTime: startTime,
      endTime: endTime,
      isOvernightShift: isOvernightShift,
    );

    await saveSectionShift(shift);
    _defaultShifts[sectionName] = shift;
  }

  /// Check if employee is late based on section shift (no grace period)
  static bool isEmployeeLate(String checkInTime, SectionShift shift) {
    try {
      final checkIn = _parseTime(checkInTime);
      final shiftStart = _parseTime(shift.startTime);

      return checkIn.isAfter(shiftStart);
    } catch (e) {
      return false;
    }
  }

  /// Check if employee is on time
  static bool isEmployeeOnTime(String checkInTime, SectionShift shift) {
    return !isEmployeeLate(checkInTime, shift);
  }

  /// Check if employee arrived early (before shift start time)
  static bool isEmployeeEarly(String checkInTime, SectionShift shift) {
    try {
      final checkIn = _parseTime(checkInTime);
      final shiftStart = _parseTime(shift.startTime);

      return checkIn.isBefore(shiftStart);
    } catch (e) {
      return false;
    }
  }

  /// Parse time string to DateTime (today's date with the time)
  static DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// Get shift duration in hours
  static double getShiftDurationHours(SectionShift shift) {
    try {
      final start = _parseTime(shift.startTime);
      final end = _parseTime(shift.endTime);
      
      if (shift.isOvernightShift) {
        // For overnight shifts, add 24 hours to end time
        final adjustedEnd = end.add(const Duration(days: 1));
        return adjustedEnd.difference(start).inMinutes / 60.0;
      } else {
        return end.difference(start).inMinutes / 60.0;
      }
    } catch (e) {
      return 8.0; // Default 8 hours
    }
  }

  /// Get formatted shift time display
  static String getShiftTimeDisplay(SectionShift shift) {
    if (shift.isOvernightShift) {
      return '${shift.startTime} - ${shift.endTime} (Next Day)';
    } else {
      return '${shift.startTime} - ${shift.endTime}';
    }
  }
}
