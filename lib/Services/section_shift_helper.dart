/// Section Shift Helper
/// 
/// This helper provides section-specific shift check-in times and punctuality calculations
/// for PDF generation and attendance reporting.
class SectionShiftHelper {
  
  // ==================== SECTION SHIFT CONFIGURATIONS ====================
  
  /// Section-specific check-in times (24-hour format)
  /// NOTE: These times are used ONLY for PDF punctuality calculations
  /// Attendance marking still follows the existing 4PM-4PM shift logic
  ///
  /// Punctuality Rules for ALL sections:
  /// - Early: 15 minutes before expected time
  /// - On Time: Expected time + 5 minutes grace period
  /// - Late: After 5-minute grace period
  static const Map<String, Map<String, dynamic>> sectionShifts = {
    'Admin office': {
      'checkInTime': '16:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '4:00 PM check-in (Early: 3:45-3:59 PM, On Time: 4:00-4:05 PM, Late: after 4:05 PM)'
    },
    'Fancy': {
      'checkInTime': '05:45',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '5:45 AM check-in (Early: 5:30-5:44 AM, On Time: 5:45-5:50 AM, Late: after 5:50 AM)'
    },
    'KK': {
      'checkInTime': '06:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '6:00 AM check-in (Early: 5:45-5:59 AM, On Time: 6:00-6:05 AM, Late: after 6:05 AM)'
    },
    'Anchor': {
      'checkInTime': '20:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '8:00 PM check-in (Early: 7:45-7:59 PM, On Time: 8:00-8:05 PM, Late: after 8:05 PM)'
    },
    'Soldering': {
      'checkInTime': '02:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '2:00 AM check-in (Early: 1:45-1:59 AM, On Time: 2:00-2:05 AM, Late: after 2:05 AM)'
    },
    'Wire': {
      'checkInTime': '17:30',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '5:30 PM check-in (Early: 5:15-5:29 PM, On Time: 5:30-5:35 PM, Late: after 5:35 PM)'
    },
    'Joint': {
      'checkInTime': '03:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '3:00 AM check-in (Early: 2:45-2:59 AM, On Time: 3:00-3:05 AM, Late: after 3:05 AM)'
    },
    'V chain': {
      'checkInTime': '02:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '2:00 AM check-in (Early: 1:45-1:59 AM, On Time: 2:00-2:05 AM, Late: after 2:05 AM)'
    },
    'Cutting': {
      'checkInTime': '06:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '6:00 AM check-in (Early: 5:45-5:59 AM, On Time: 6:00-6:05 AM, Late: after 6:05 AM)'
    },
    'Box chain': {
      'checkInTime': '09:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '9:00 AM check-in (Early: 8:45-8:59 AM, On Time: 9:00-9:05 AM, Late: after 9:05 AM)'
    },
    'Polish': {
      'checkInTime': '09:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '9:00 AM check-in (Early: 8:45-8:59 AM, On Time: 9:00-9:05 AM, Late: after 9:05 AM)'
    },
    'Supervisors': {
      'checkInTime': '09:00',
      'gracePeriodMinutes': 5,
      'earlyWindowMinutes': 15,
      'description': '9:00 AM check-in (Early: 8:45-8:59 AM, On Time: 9:00-9:05 AM, Late: after 9:05 AM)'
    },
  };

  // ==================== PUNCTUALITY CALCULATION METHODS ====================
  
  /// Get section shift configuration
  static Map<String, dynamic>? getSectionShift(String sectionName) {
    return sectionShifts[sectionName];
  }
  
  /// Calculate punctuality status for an employee
  /// 
  /// Returns: 'Early', 'On Time', 'Late', or 'Absent'
  static String calculatePunctualityStatus(String? checkInTime, String section) {
    if (checkInTime == null || checkInTime.isEmpty || checkInTime == '-') {
      return 'Absent';
    }
    
    final sectionShift = getSectionShift(section);
    if (sectionShift == null) {
      return 'Present'; // Default if section not configured
    }
    
    try {
      final expectedCheckIn = sectionShift['checkInTime'] as String;
      final gracePeriodMinutes = sectionShift['gracePeriodMinutes'] as int;
      final earlyWindowMinutes = sectionShift['earlyWindowMinutes'] as int? ?? 15; // Default 15 minutes
      
      // Parse times
      final checkInParts = checkInTime.split(':');
      final expectedParts = expectedCheckIn.split(':');

      if (checkInParts.length != 2 || expectedParts.length != 2) {
        return 'Present'; // Default if time format is invalid
      }

      final checkInHour = int.tryParse(checkInParts[0]);
      final checkInMinute = int.tryParse(checkInParts[1]);
      final expectedHour = int.tryParse(expectedParts[0]);
      final expectedMinute = int.tryParse(expectedParts[1]);

      if (checkInHour == null || checkInMinute == null || expectedHour == null || expectedMinute == null ||
          checkInHour < 0 || checkInHour > 23 || checkInMinute < 0 || checkInMinute > 59) {
        return 'Present'; // Default if parsing fails or invalid time
      }
      
      // Convert to minutes for easier comparison
      final checkInTotalMinutes = checkInHour * 60 + checkInMinute;
      final expectedTotalMinutes = expectedHour * 60 + expectedMinute;
      final graceEndMinutes = expectedTotalMinutes + gracePeriodMinutes;
      final earlyStartMinutes = expectedTotalMinutes - earlyWindowMinutes;

      // Determine punctuality status based on new rules:
      // Early: earlyWindowMinutes before expected time (e.g., 2:45-2:59 AM for 3:00 AM)
      // On Time: expected time + grace period (e.g., 3:00-3:05 AM)
      // Late: after grace period (e.g., after 3:05 AM)

      if (checkInTotalMinutes < earlyStartMinutes) {
        return 'Early'; // More than earlyWindowMinutes early (very early)
      } else if (checkInTotalMinutes < expectedTotalMinutes) {
        return 'Early'; // Within early window (earlyWindowMinutes before expected time)
      } else if (checkInTotalMinutes <= graceEndMinutes) {
        return 'On Time'; // Within grace period (including exactly on time)
      } else {
        return 'Late'; // After grace period
      }
      
    } catch (e) {
      return 'Present'; // Default if calculation fails
    }
  }
  
  /// Check if employee is late
  static bool isEmployeeLate(String? checkInTime, String section) {
    return calculatePunctualityStatus(checkInTime, section) == 'Late';
  }
  
  /// Check if employee is early
  static bool isEmployeeEarly(String? checkInTime, String section) {
    return calculatePunctualityStatus(checkInTime, section) == 'Early';
  }
  
  /// Check if employee is on time (including grace period)
  static bool isEmployeeOnTime(String? checkInTime, String section) {
    final status = calculatePunctualityStatus(checkInTime, section);
    return status == 'On Time' || status == 'Early';
  }
  
  /// Get formatted shift time display for a section
  static String getShiftTimeDisplay(String section) {
    final sectionShift = getSectionShift(section);
    if (sectionShift == null) {
      return 'Not configured';
    }
    
    final checkInTime = sectionShift['checkInTime'] as String;
    final gracePeriodMinutes = sectionShift['gracePeriodMinutes'] as int;
    
    // Convert 24-hour to 12-hour format for display
    final parts = checkInTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    
    String displayTime;
    if (hour == 0) {
      displayTime = '12:$minute AM';
    } else if (hour < 12) {
      displayTime = '$hour:$minute AM';
    } else if (hour == 12) {
      displayTime = '12:$minute PM';
    } else {
      displayTime = '${hour - 12}:$minute PM';
    }
    
    final earlyWindowMinutes = sectionShift['earlyWindowMinutes'] as int? ?? 15;
    return '$displayTime (Early: ${earlyWindowMinutes}min before, Grace: ${gracePeriodMinutes}min after)';
  }
  
  /// Get all configured sections
  static List<String> getAllSections() {
    return sectionShifts.keys.toList();
  }
  
  /// Get sections with early morning shifts (before 7 AM)
  static List<String> getEarlyMorningSections() {
    return sectionShifts.entries
        .where((entry) {
          final checkInTime = entry.value['checkInTime'] as String;
          final hour = int.parse(checkInTime.split(':')[0]);
          return hour < 7;
        })
        .map((entry) => entry.key)
        .toList();
  }
}
