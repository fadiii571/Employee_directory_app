import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/section_shift_helper.dart';

class AttendanceDashboard extends StatefulWidget {
  const AttendanceDashboard({Key? key}) : super(key: key);

  @override
  State<AttendanceDashboard> createState() => _AttendanceDashboardState();
}

class _AttendanceDashboardState extends State<AttendanceDashboard> {
  Map<String, int> attendanceCounts = {
    'Early': 0,
    'On Time': 0,
    'Late': 0,
    'Absent': 0,
  };
  
  int totalEmployees = 0;
  bool isLoading = true;
  String selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadAttendanceData();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDateTime) {
      setState(() {
        selectedDateTime = picked;
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      loadAttendanceData();
    }
  }

  Future<void> loadAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get attendance records for selected date from subcollection
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(selectedDate)
          .collection('records')
          .get();

      if (attendanceSnapshot.docs.isNotEmpty) {
        // Convert subcollection documents to map format
        Map<String, dynamic> attendanceData = {};
        for (var doc in attendanceSnapshot.docs) {
          final data = doc.data();
          final employeeName = data['name'] ?? data['employeeName'] ?? 'Unknown';
          attendanceData[employeeName] = data;
        }

        await calculateAttendanceCounts(attendanceData);
      } else {
        resetCounts();
      }
    } catch (e) {
      resetCounts();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> calculateAttendanceCounts(Map<String, dynamic> attendanceData) async {
    Map<String, int> counts = {
      'Early': 0,
      'On Time': 0,
      'Late': 0,
      'Absent': 0,
    };

    int total = 0;

    // Get all employees from the database
    final employeesSnapshot = await FirebaseFirestore.instance
        .collection('Employees')
        .get();

    for (var employeeDoc in employeesSnapshot.docs) {
      final employeeData = employeeDoc.data();
      final employeeName = employeeData['name'] ?? '';
      final section = employeeData['section'] ?? '';

      total++;

      // Check if employee has attendance record for today
      final employeeAttendance = attendanceData[employeeName];
      
      if (employeeAttendance != null && employeeAttendance['logs'] != null) {
        final logs = List<Map<String, dynamic>>.from(employeeAttendance['logs']);
        
        // Find check-in log
        final checkInLog = logs.firstWhere(
          (log) => (log['type'] == 'Check In' || log['type'] == 'In') && log['time'] != null,
          orElse: () => <String, dynamic>{},
        );

        if (checkInLog.isNotEmpty) {
          // Convert time to 24-hour format for punctuality calculation
          String checkInTime = checkInLog['time'].toString();
          String timeIn24HourFormat = convertTo24HourFormat(checkInTime);
          
          // Calculate punctuality status
          String punctualityStatus = SectionShiftHelper.calculatePunctualityStatus(
            timeIn24HourFormat, 
            section
          );
          
          counts[punctualityStatus] = (counts[punctualityStatus] ?? 0) + 1;
        } else {
          // No check-in found
          counts['Absent'] = (counts['Absent'] ?? 0) + 1;
        }
      } else {
        // No attendance record
        counts['Absent'] = (counts['Absent'] ?? 0) + 1;
      }
    }

    setState(() {
      attendanceCounts = counts;
      totalEmployees = total;
    });
  }

  String convertTo24HourFormat(String timeStr) {
    try {
      // List of possible time formats
      final formats = [
        DateFormat('hh:mm a'),    // 03:01 AM
        DateFormat('HH:mm'),      // 03:01 (24-hour)
        DateFormat('h:mm a'),     // 3:01 AM
        DateFormat('H:mm'),       // 3:01 (24-hour)
        DateFormat('hh:mm'),      // 03:01 (12-hour without AM/PM)
      ];

      for (final format in formats) {
        try {
          final parsedTime = format.parse(timeStr);
          return DateFormat('HH:mm').format(parsedTime);
        } catch (e) {
          continue;
        }
      }
      return timeStr;
    } catch (e) {
      return timeStr;
    }
  }

  void resetCounts() {
    setState(() {
      attendanceCounts = {
        'Early': 0,
        'On Time': 0,
        'Late': 0,
        'Absent': 0,
      };
      totalEmployees = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAttendanceData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Picker Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDateTime),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.date_range, size: 18),
                              label: const Text('Select Different Date'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Punctuality Overview (TOP PRIORITY)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics, color: Colors.blue, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Punctuality Overview',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPunctualityGraph(),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Punctuality Count Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildCountCard('Early', attendanceCounts['Early']!, Colors.orange),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCountCard('On Time', attendanceCounts['On Time']!, Colors.green),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCountCard('Late', attendanceCounts['Late']!, Colors.red),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCountCard('Absent', attendanceCounts['Absent']!, Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Summary Cards (MOVED TO BOTTOM)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Employees',
                          totalEmployees.toString(),
                          Colors.blue,
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSummaryCard(
                          'Present Today',
                          (totalEmployees - attendanceCounts['Absent']!).toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPunctualityGraph() {
    final maxCount = attendanceCounts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No attendance data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: attendanceCounts.entries.map((entry) {
        final percentage = maxCount > 0 ? (entry.value / maxCount) : 0.0;
        Color barColor;
        
        switch (entry.key) {
          case 'Early':
            barColor = Colors.orange;
            break;
          case 'On Time':
            barColor = Colors.green;
            break;
          case 'Late':
            barColor = Colors.red;
            break;
          case 'Absent':
            barColor = Colors.grey;
            break;
          default:
            barColor = Colors.blue;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
