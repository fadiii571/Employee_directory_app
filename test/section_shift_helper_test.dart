import 'package:flutter_test/flutter_test.dart';
import 'package:student_projectry_app/Services/section_shift_helper.dart';

void main() {
  group('SectionShiftHelper Tests', () {
    
    test('Admin office punctuality calculation', () {
      // Admin office: 4:00 PM check-in with 5 minutes grace period and 15 minutes early window

      // Very early arrival (before 3:45 PM)
      expect(SectionShiftHelper.calculatePunctualityStatus('15:30', 'Admin office'), 'Early');

      // Early arrival (3:45-3:59 PM)
      expect(SectionShiftHelper.calculatePunctualityStatus('15:50', 'Admin office'), 'Early');

      // On time (4:00 PM exactly)
      expect(SectionShiftHelper.calculatePunctualityStatus('16:00', 'Admin office'), 'On Time');

      // Within grace period (4:03 PM)
      expect(SectionShiftHelper.calculatePunctualityStatus('16:03', 'Admin office'), 'On Time');
       
      // End of grace period (4:05 PM)
      expect(SectionShiftHelper.calculatePunctualityStatus('16:10', 'Admin office'), 'On Time');
      
      // Late (after 4:05 PM)
      expect(SectionShiftHelper.calculatePunctualityStatus('16:11', 'Admin office'), 'Late');

      // Absent
      expect(SectionShiftHelper.calculatePunctualityStatus(null, 'Admin office'), 'Absent');
      expect(SectionShiftHelper.calculatePunctualityStatus('', 'Admin office'), 'Absent');
      expect(SectionShiftHelper.calculatePunctualityStatus('-', 'Admin office'), 'Absent');
    });
    
    test('Joint section punctuality calculation (example format)', () {
      // Joint: 3:00 AM check-in with 5 minutes grace period and 15 minutes early window
      // Early: 2:45-2:59 AM, On Time: 3:00-3:05 AM, Late: after 3:05 AM

      // Very early arrival (before 2:45 AM)
      expect(SectionShiftHelper.calculatePunctualityStatus('02:30', 'Joint'), 'Early');

      // Early arrival (2:45-2:59 AM)
      expect(SectionShiftHelper.calculatePunctualityStatus('02:45', 'Joint'), 'Early');
      expect(SectionShiftHelper.calculatePunctualityStatus('02:50', 'Joint'), 'Early');
      expect(SectionShiftHelper.calculatePunctualityStatus('02:59', 'Joint'), 'Early');

      // On time (3:00-3:05 AM)
      expect(SectionShiftHelper.calculatePunctualityStatus('03:00', 'Joint'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('03:03', 'Joint'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('03:05', 'Joint'), 'On Time');

      // Late (after 3:05 AM)
      expect(SectionShiftHelper.calculatePunctualityStatus('03:06', 'Joint'), 'Late');
      expect(SectionShiftHelper.calculatePunctualityStatus('03:10', 'Joint'), 'Late');
    });
    
    test('KK section punctuality calculation', () {
      // KK: 6:00 AM check-in with 5 minutes grace period and 15 minutes early window

      // Early arrival (more than 15 minutes early)
      expect(SectionShiftHelper.calculatePunctualityStatus('05:40', 'KK'), 'Early');

      // Early arrival (within 15 minutes early window)
      expect(SectionShiftHelper.calculatePunctualityStatus('05:45', 'KK'), 'Early');
      expect(SectionShiftHelper.calculatePunctualityStatus('05:55', 'KK'), 'Early');

      // On time
      expect(SectionShiftHelper.calculatePunctualityStatus('06:00', 'KK'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('06:03', 'KK'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('06:05', 'KK'), 'On Time');

      // Late
      expect(SectionShiftHelper.calculatePunctualityStatus('06:06', 'KK'), 'Late');
    });
    
    test('Anchor section punctuality calculation', () {
      // Anchor: 8:00 PM check-in with 5 minutes grace period

      // Early arrival
      expect(SectionShiftHelper.calculatePunctualityStatus('19:40', 'Anchor'), 'Early');

      // On time
      expect(SectionShiftHelper.calculatePunctualityStatus('20:00', 'Anchor'), 'On Time');

      // Within grace period
      expect(SectionShiftHelper.calculatePunctualityStatus('20:03', 'Anchor'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('20:05', 'Anchor'), 'On Time');

      // Late
      expect(SectionShiftHelper.calculatePunctualityStatus('20:06', 'Anchor'), 'Late');
    });

    test('Soldering section punctuality calculation', () {
      // Soldering: 2:00 AM check-in with 5 minutes grace period

      // Early arrival
      expect(SectionShiftHelper.calculatePunctualityStatus('01:40', 'Soldering'), 'Early');

      // On time
      expect(SectionShiftHelper.calculatePunctualityStatus('02:00', 'Soldering'), 'On Time');

      // Within grace period
      expect(SectionShiftHelper.calculatePunctualityStatus('02:03', 'Soldering'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('02:05', 'Soldering'), 'On Time');

      // Late
      expect(SectionShiftHelper.calculatePunctualityStatus('02:06', 'Soldering'), 'Late');
    });

    test('Wire section punctuality calculation', () {
      // Wire: 5:30 PM check-in with 5 minutes grace period

      // Early arrival
      expect(SectionShiftHelper.calculatePunctualityStatus('17:10', 'Wire'), 'Early');

      // On time
      expect(SectionShiftHelper.calculatePunctualityStatus('17:30', 'Wire'), 'On Time');

      // Within grace period
      expect(SectionShiftHelper.calculatePunctualityStatus('17:33', 'Wire'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('17:35', 'Wire'), 'On Time');

      // Late
      expect(SectionShiftHelper.calculatePunctualityStatus('17:36', 'Wire'), 'Late');
    });

    test('Supervisors section punctuality calculation', () {
      // Supervisors: 9:00 AM check-in with 5 minutes grace period (updated from 30 minutes)

      // Early arrival
      expect(SectionShiftHelper.calculatePunctualityStatus('08:40', 'Supervisors'), 'Early');

      // On time
      expect(SectionShiftHelper.calculatePunctualityStatus('09:00', 'Supervisors'), 'On Time');

      // Within grace period
      expect(SectionShiftHelper.calculatePunctualityStatus('09:03', 'Supervisors'), 'On Time');
      expect(SectionShiftHelper.calculatePunctualityStatus('09:05', 'Supervisors'), 'On Time');

      // Late
      expect(SectionShiftHelper.calculatePunctualityStatus('09:06', 'Supervisors'), 'Late');
    });
    
    test('Unknown section handling', () {
      // Unknown section should return 'Present' as default
      expect(SectionShiftHelper.calculatePunctualityStatus('09:00', 'Unknown Section'), 'Present');
    });
    
    test('Invalid time format handling', () {
      // Invalid time formats should return 'Present' as default
      expect(SectionShiftHelper.calculatePunctualityStatus('invalid', 'Admin office'), 'Present');
      expect(SectionShiftHelper.calculatePunctualityStatus('25:00', 'Admin office'), 'Present');
    });
    
    test('Helper methods', () {
      // Test helper methods with new 5-minute grace period
      expect(SectionShiftHelper.isEmployeeLate('16:06', 'Admin office'), true);  // After 4:05 PM
      expect(SectionShiftHelper.isEmployeeLate('16:05', 'Admin office'), false); // Within grace period

      expect(SectionShiftHelper.isEmployeeEarly('15:30', 'Admin office'), true);  // Before 3:45 PM
      expect(SectionShiftHelper.isEmployeeEarly('16:00', 'Admin office'), false); // Exactly on time

      expect(SectionShiftHelper.isEmployeeOnTime('16:03', 'Admin office'), true);  // Within grace period
      expect(SectionShiftHelper.isEmployeeOnTime('15:50', 'Admin office'), true); // Early is also considered "on time"
      expect(SectionShiftHelper.isEmployeeOnTime('16:06', 'Admin office'), false); // Late
    });
    
    test('Get shift time display', () {
      expect(SectionShiftHelper.getShiftTimeDisplay('Admin office'), '4:00 PM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Fancy'), '5:45 AM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('KK'), '6:00 AM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Anchor'), '8:00 PM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Soldering'), '2:00 AM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Wire'), '5:30 PM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Supervisors'), '9:00 AM (Early: 15min before, Grace: 5min after)');
      expect(SectionShiftHelper.getShiftTimeDisplay('Unknown'), 'Not configured');
    });
    
    test('Get early morning sections', () {
      final earlyMorningSections = SectionShiftHelper.getEarlyMorningSections();
      expect(earlyMorningSections, contains('Fancy'));
      expect(earlyMorningSections, contains('KK'));
      expect(earlyMorningSections, contains('Soldering'));
      expect(earlyMorningSections, contains('Joint'));
      expect(earlyMorningSections, contains('V chain'));
      expect(earlyMorningSections, contains('Cutting'));
      expect(earlyMorningSections, isNot(contains('Admin office')));
      expect(earlyMorningSections, isNot(contains('Anchor')));
      expect(earlyMorningSections, isNot(contains('Wire')));
    });
  });
}
