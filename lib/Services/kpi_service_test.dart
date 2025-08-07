import 'package:flutter/material.dart';
import 'kpi_service.dart';
import '../model/kpi_models.dart';

/// KPI Service Test Functions
/// 
/// This file contains test functions to verify that the KPI service
/// is working correctly after optimization.
class KPIServiceTest {
  
  /// Test employee KPI calculation
  static Future<void> testEmployeeKPI() async {
    try {
      print('🧪 Testing Employee KPI Calculation...');
      
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      
      // Test with a sample employee ID (replace with actual ID)
      const testEmployeeId = 'test_employee_id';
      
      final kpi = await KPIService.calculateEmployeeAttendanceKPI(
        employeeId: testEmployeeId,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('✅ Employee KPI Test Results:');
      print('   Employee: ${kpi.employeeName}');
      print('   Section: ${kpi.section}');
      print('   Attendance Rate: ${kpi.attendanceRate.toStringAsFixed(2)}%');
      print('   Punctuality Rate: ${kpi.punctualityRate.toStringAsFixed(2)}%');
      print('   Early Arrival Rate: ${kpi.earlyArrivalRate.toStringAsFixed(2)}%');
      print('   Present Days: ${kpi.presentDays}/${kpi.totalWorkingDays}');
      
    } catch (e) {
      print('❌ Employee KPI Test Failed: $e');
    }
  }
  
  /// Test section KPI calculation
  static Future<void> testSectionKPI() async {
    try {
      print('🧪 Testing Section KPI Calculation...');
      
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      
      // Test with Joint section
      const testSection = 'Joint';
      
      final sectionSummary = await KPIService.calculateSectionAttendanceSummary(
        sectionName: testSection,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('✅ Section KPI Test Results:');
      print('   Section: ${sectionSummary.sectionName}');
      print('   Total Employees: ${sectionSummary.totalEmployees}');
      print('   Present Employees: ${sectionSummary.presentEmployees}');
      print('   Section Attendance Rate: ${sectionSummary.sectionAttendanceRate.toStringAsFixed(2)}%');
      print('   Section Punctuality Rate: ${sectionSummary.sectionPunctualityRate.toStringAsFixed(2)}%');
      print('   Section Early Arrival Rate: ${sectionSummary.sectionEarlyArrivalRate.toStringAsFixed(2)}%');
      print('   Check-in Time: ${sectionSummary.sectionShift.checkInTime}');
      print('   Grace Period: ${sectionSummary.sectionShift.gracePeriodMinutes} minutes');
      
    } catch (e) {
      print('❌ Section KPI Test Failed: $e');
    }
  }
  
  /// Test KPI data retrieval with filter
  static Future<void> testKPIDataRetrieval() async {
    try {
      print('🧪 Testing KPI Data Retrieval...');
      
      final filter = KPIFilter(
        timeFrame: KPITimeFrame.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        department: 'Joint',
      );
      
      final result = await KPIService.getAttendanceKPIData(filter);
      
      print('✅ KPI Data Retrieval Test Results:');
      print('   Data Type: ${result['type']}');
      print('   Cached: ${result['cached'] ?? false}');
      
      if (result['type'] == 'section') {
        final sectionData = result['data'] as SectionAttendanceSummary;
        print('   Section: ${sectionData.sectionName}');
        print('   Employees: ${sectionData.totalEmployees}');
      }
      
    } catch (e) {
      print('❌ KPI Data Retrieval Test Failed: $e');
    }
  }
  
  /// Test cache functionality
  static Future<void> testCacheFunctionality() async {
    try {
      print('🧪 Testing Cache Functionality...');
      
      final filter = KPIFilter(
        timeFrame: KPITimeFrame.weekly,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
        department: 'Anchor',
      );
      
      // First call - should not be cached
      final stopwatch1 = Stopwatch()..start();
      final result1 = await KPIService.getAttendanceKPIData(filter);
      stopwatch1.stop();
      
      // Second call - should be cached
      final stopwatch2 = Stopwatch()..start();
      final result2 = await KPIService.getAttendanceKPIData(filter);
      stopwatch2.stop();
      
      print('✅ Cache Test Results:');
      print('   First call time: ${stopwatch1.elapsedMilliseconds}ms');
      print('   Second call time: ${stopwatch2.elapsedMilliseconds}ms');
      print('   First call cached: ${result1['cached'] ?? false}');
      print('   Second call cached: ${result2['cached'] ?? false}');
      
      if (stopwatch2.elapsedMilliseconds < stopwatch1.elapsedMilliseconds) {
        print('   ✅ Cache is working - second call was faster!');
      } else {
        print('   ⚠️ Cache might not be working optimally');
      }
      
    } catch (e) {
      print('❌ Cache Test Failed: $e');
    }
  }
  
  /// Run all KPI service tests
  static Future<void> runAllTests() async {
    print('🚀 Starting KPI Service Tests...\n');
    
    await testEmployeeKPI();
    print('');
    
    await testSectionKPI();
    print('');
    
    await testKPIDataRetrieval();
    print('');
    
    await testCacheFunctionality();
    print('');
    
    print('🎉 KPI Service Tests Completed!');
  }
  
  /// Test KPI service with UI integration
  static Widget buildTestWidget() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KPI Service Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'KPI Service Test Functions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: testEmployeeKPI,
              child: const Text('Test Employee KPI'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: testSectionKPI,
              child: const Text('Test Section KPI'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: testKPIDataRetrieval,
              child: const Text('Test KPI Data Retrieval'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: testCacheFunctionality,
              child: const Text('Test Cache Functionality'),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Run All Tests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text(
              'Check the console output for test results.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Example usage in a screen
class KPITestScreen extends StatelessWidget {
  const KPITestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KPIServiceTest.buildTestWidget();
  }
}
