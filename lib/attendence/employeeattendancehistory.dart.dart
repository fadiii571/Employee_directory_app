import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/widgets/generatepdf.dart' show generateAttendancePdf, generateEmployeeAttendancePdf;
import 'package:student_projectry_app/Services/services.dart';
import 'package:student_projectry_app/Services/employee_service.dart';

class EmployeeQRDailyLogHistoryScreen extends StatefulWidget {
  const EmployeeQRDailyLogHistoryScreen({super.key});

  @override
  State<EmployeeQRDailyLogHistoryScreen> createState() =>
      _EmployeeQRDailyLogHistoryScreenState();
}

class _EmployeeQRDailyLogHistoryScreenState extends State<EmployeeQRDailyLogHistoryScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedSection = '';
  String selectedEmployee = '';
  String viewType = 'Daily';
  List<Map<String, dynamic>> currentVisibleLogs = [];
  List<Map<String, dynamic>> allEmployees = [];
  bool _isInitialized = false;

  // Available sections for filter
  final List<String> availableSections = [
    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
  ];

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  /// Get employees filtered by selected section
  List<Map<String, dynamic>> getFilteredEmployees() {
    if (selectedSection.isEmpty) {
      return allEmployees;
    }
    return allEmployees.where((employee) =>
      employee['section'] == selectedSection
    ).toList();
  }

  /// Get selected employee name
  String getSelectedEmployeeName() {
    if (selectedEmployee.isEmpty) return '';
    final employee = allEmployees.firstWhere(
      (emp) => emp['id'] == selectedEmployee,
      orElse: () => {'name': 'Unknown Employee'},
    );
    return employee['name'] ?? 'Unknown Employee';
  }

  /// Get selected employee section
  String getSelectedEmployeeSection() {
    if (selectedEmployee.isEmpty) return '';
    final employee = allEmployees.firstWhere(
      (emp) => emp['id'] == selectedEmployee,
      orElse: () => {'section': 'Unknown Section'},
    );
    return employee['section'] ?? 'Unknown Section';
  }

  /// Generate PDF report for selected employee
  Future<void> _generateEmployeePdf(List<Map<String, dynamic>> logs) async {
    if (selectedEmployee.isEmpty || logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No employee selected or no attendance data available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // The `logs` variable already contains the correct data structure.
      // We just need to ensure it's sorted and the date range is correct.
      final attendanceData = List<Map<String, dynamic>>.from(logs);

      if (attendanceData.isEmpty) {
        throw Exception('No valid attendance records found for the selected employee');
      }

      // Sort by date
      attendanceData.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date']);
          final dateB = DateTime.parse(b['date']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      // Generate date range string
      String dateRange = 'Unknown Period';
      if (attendanceData.isNotEmpty) {
        try {
          final firstDate = attendanceData.first['date'];
          final lastDate = attendanceData.last['date'];

          if (firstDate == lastDate) {
            dateRange = DateFormat('MMMM dd, yyyy').format(DateTime.parse(firstDate));
          } else {
            dateRange = '${DateFormat('MMM dd').format(DateTime.parse(firstDate))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(lastDate))}';
          }
        } catch (e) {
          dateRange = 'Invalid Date Range';
        }
      }

      // Validate employee data
      final employeeName = getSelectedEmployeeName();
      final employeeSection = getSelectedEmployeeSection();

      if (employeeName.isEmpty || employeeName == 'Unknown Employee') {
        throw Exception('Employee information not available');
      }

      // Generate PDF
      await generateEmployeeAttendancePdf(
        employeeName: employeeName,
        employeeSection: employeeSection,
        attendanceData: attendanceData,
        dateRange: dateRange,
        viewType: viewType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Initialize employee cache for better performance
  Future<void> _initializeData() async {
    if (!_isInitialized) {
      try {
        await preloadEmployeeData();

        // Load all employees for the filter dropdown (including those without isActive field)
        final employees = await EmployeeService.getAllEmployeesWithStatus();

        setState(() {
          allEmployees = employees;
          _isInitialized = true;
        });
      } catch (e) {
        setState(() {
          _isInitialized = true; // Set to true even on error to prevent infinite loading
        });
      }
    }
  }

  // Helper function to get section color
  Color getSectionColor(String section) {
    switch (section.toLowerCase()) {
      case 'admin office': return Colors.purple;
      case 'fancy': return Colors.pink;
      case 'kk': return Colors.orange;
      case 'anchor': return Colors.blue;
      case 'soldering': return Colors.red;
      case 'wire': return Colors.green;
      case 'joint': return Colors.teal;
      case 'v chain': return Colors.indigo;
      case 'cutting': return Colors.brown;
      case 'box chain': return Colors.cyan;
      case 'polish': return Colors.amber;
      case 'supervisors': return Colors.deepPurple;
      default: return Colors.grey;
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Widget buildLogList(List logs) {
  if (logs.isEmpty) return const Text("No logs");

  logs.removeWhere((log) => log['time'] == null); // 🚨 Prevent parsing null

  // Debug: Print log types if there are issues
  if (logs.isNotEmpty) {
    debugPrint('Log types found: ${logs.map((log) => log['type']).toSet().toList()}');
  }

  logs.sort((a, b) {
    try {
      final timeA = _parseTimeString(a['time']?.toString() ?? '');
      final timeB = _parseTimeString(b['time']?.toString() ?? '');

      if (timeA == null || timeB == null) return 0;
      return timeA.compareTo(timeB);
    } catch (e) {
      return 0; // Keep original order if parsing fails
    }
  });

  // Handle both old and new log type formats
  final inLogs = logs.where((log) =>
    log['type'] == 'Check In' || log['type'] == 'In'
  ).toList();
  final outLogs = logs.where((log) =>
    log['type'] == 'Check Out' || log['type'] == 'Out'
  ).toList();

  debugPrint('Found ${inLogs.length} check-in logs and ${outLogs.length} check-out logs');

  final inTimes = inLogs.map((log) => _formatTimeTo12Hour(log['time'])).join(', ');
  final outTimes = outLogs.map((log) => _formatTimeTo12Hour(log['time'])).join(', ');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (inLogs.isNotEmpty)
        Text("In: $inTimes", style: const TextStyle(color: Colors.green)),
      if (outLogs.isNotEmpty)
        Text("Out: $outTimes", style: const TextStyle(color: Colors.red)),
    ],
  );
}


 Duration calculateTotalDuration(List logs) {
  if (logs.isEmpty) {
    return Duration.zero;
  }

  // Find check-in and check-out logs (handle both old and new formats)
  final checkInLog = logs.firstWhere(
    (log) => (log['type'] == 'Check In' || log['type'] == 'In') && log['time'] != null,
    orElse: () => <String, dynamic>{},
  );

  final checkOutLog = logs.firstWhere(
    (log) => (log['type'] == 'Check Out' || log['type'] == 'Out') && log['time'] != null,
    orElse: () => <String, dynamic>{},
  );

  // If either check-in or check-out is missing, return zero
  if (checkInLog.isEmpty || checkOutLog.isEmpty) {
    return Duration.zero;
  }

  try {
    final checkInTimeStr = checkInLog['time'].toString().trim();
    final checkOutTimeStr = checkOutLog['time'].toString().trim();

    // Parse times with multiple format support
    final checkInTime = _parseTimeString(checkInTimeStr);
    final checkOutTime = _parseTimeString(checkOutTimeStr);

    if (checkInTime == null || checkOutTime == null) {
      debugPrint('Failed to parse times: checkIn="$checkInTimeStr", checkOut="$checkOutTimeStr"');
      return Duration.zero;
    }

    // Create DateTime objects for the same day to calculate duration properly
    final today = DateTime.now();
    final checkInDateTime = DateTime(today.year, today.month, today.day, checkInTime.hour, checkInTime.minute);
    final checkOutDateTime = DateTime(today.year, today.month, today.day, checkOutTime.hour, checkOutTime.minute);

    // Handle cross-day scenarios (e.g., check-in at 3:00 AM, check-out at 9:00 AM)
    Duration totalDuration;
    if (checkOutDateTime.isBefore(checkInDateTime)) {
      // Check-out is next day (e.g., check-in 3:00 AM, check-out 9:00 AM next day)
      final nextDayCheckOut = checkOutDateTime.add(const Duration(days: 1));
      totalDuration = nextDayCheckOut.difference(checkInDateTime);
    } else {
      // Same day check-in and check-out
      totalDuration = checkOutDateTime.difference(checkInDateTime);
    }

    // Ensure we don't return negative duration
    return totalDuration.isNegative ? Duration.zero : totalDuration;
  } catch (e) {
    debugPrint('Error calculating duration: $e');
    return Duration.zero;
  }
}


  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  /// Safely get profile image URL from record
  String _getProfileImageUrl(Map<String, dynamic> record) {
    final profileImageUrl = record['profileImageUrl'];
    if (profileImageUrl == null) return '';
    if (profileImageUrl is String) return profileImageUrl;
    if (profileImageUrl is int) return ''; // If it's an int (timestamp), return empty
    return profileImageUrl.toString();
  }

  /// Safely get employee name from record
  String _getEmployeeName(Map<String, dynamic> record) {
    final name = record['name'];
    if (name == null) return 'Unknown';
    if (name is String) return name;
    return name.toString();
  }

  /// Parse time string with multiple format support
  DateTime? _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) return null;

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
        return format.parse(timeStr);
      } catch (e) {
        // Try next format
        continue;
      }
    }

    debugPrint('Could not parse time string: "$timeStr"');
    return null;
  }

  /// Format time to 12-hour format (AM/PM)
  String _formatTimeTo12Hour(dynamic timeValue) {
    if (timeValue == null) return '-';

    final timeStr = timeValue.toString().trim();
    if (timeStr.isEmpty) return '-';

    // If already in 12-hour format, return as is
    if (timeStr.toLowerCase().contains('am') || timeStr.toLowerCase().contains('pm')) {
      return timeStr;
    }

    // Parse the time and convert to 12-hour format
    final parsedTime = _parseTimeString(timeStr);
    if (parsedTime == null) return timeStr; // Return original if parsing fails

    return DateFormat('h:mm a').format(parsedTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee QR Attendance Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => pickDate(context),
            tooltip: 'Pick Date',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              // Summary calculation
              Map<String, Duration> summaryMap = {};
              for (var record in currentVisibleLogs) {
                final name = record['name'];
                final logs = List<Map<String, dynamic>>.from(record['logs']);
                final duration = calculateTotalDuration(logs);
                summaryMap[name] = (summaryMap[name] ?? Duration.zero) + duration;
              }

              await generateAttendancePdf(
                title: "$viewType Attendance: $formattedDate",
                logs: currentVisibleLogs,
                viewType: viewType,
                summary: viewType != 'Daily'
                    ? summaryMap.map((name, dur) => MapEntry(name, formatDuration(dur)))
                    : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // First row: View Type and Section Filter
                Row(
                  children: [
                    // View Type Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_view_day, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: viewType,
                                underline: const SizedBox(),
                                isExpanded: true,
                                items: ['Daily', 'Weekly', 'Monthly']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => viewType = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Section Filter Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: selectedSection.isNotEmpty ? selectedSection : '',
                                underline: const SizedBox(),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text("All Sections", style: TextStyle(fontWeight: FontWeight.w500))
                                  ),
                                  ...availableSections
                                      .map((section) => DropdownMenuItem(value: section, child: Text(section))),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    selectedSection = val ?? '';
                                    // Reset employee filter when section changes
                                    selectedEmployee = '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row: Employee Filter
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isInitialized
                          ? DropdownButton<String>(
                              value: selectedEmployee.isNotEmpty &&
                                     getFilteredEmployees().any((emp) => emp['id'] == selectedEmployee)
                                     ? selectedEmployee : '',
                              underline: const SizedBox(),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text("All Employees", style: TextStyle(fontWeight: FontWeight.w500))
                                ),
                                // Only show employee items if we have employees
                                if (getFilteredEmployees().isNotEmpty)
                                  ...getFilteredEmployees()
                                      .map((employee) => DropdownMenuItem(
                                        value: employee['id'] ?? '',
                                        child: Text("${employee['name'] ?? 'Unknown'} (${employee['section'] ?? 'Unknown'})")
                                      )),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  selectedEmployee = val ?? '';
                                });
                              },
                            )
                          : const Text(
                              "Loading employees...",
                              style: TextStyle(color: Colors.grey),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Show message when no employees are available
          if (_isInitialized && allEmployees.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "No employees found. Please add employees first.",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Filter Status Indicator
          if (selectedSection.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Filtered: $selectedSection',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSection = '';
                      });
                    },
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: fetchAttendanceHistory(
                selectedDate: selectedDate,
                viewType: viewType,
                selectedEmployeeId: selectedEmployee,
                employeeNames: {},
                selectedSection: selectedSection,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading attendance data...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final history = snapshot.data ?? {};
                currentVisibleLogs = history.values.expand((e) => e).toList();

                if (history.isEmpty) {
                  return const Center(child: Text("No attendance records found."));
                }

                final sortedDates = history.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                // Calculate summary map for Weekly/Monthly
                Map<String, Duration> summaryMap = {};
                for (var record in currentVisibleLogs) {
                  final name = record['name'];
                  final logs = List<Map<String, dynamic>>.from(record['logs']);
                  final duration = calculateTotalDuration(logs);
                  summaryMap[name] = (summaryMap[name] ?? Duration.zero) + duration;
                }

                return ListView(
                  children: [
                    // Employee Summary Card (when specific employee is selected)
                    if (selectedEmployee.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Employee Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getSelectedEmployeeName(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        getSelectedEmployeeSection(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        formatDuration(summaryMap.values.fold(Duration.zero, (a, b) => a + b)),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Total Hours',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${currentVisibleLogs.length} attendance record(s) found',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _generateEmployeePdf(currentVisibleLogs),
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('PDF Report'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    for (final date in sortedDates)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.grey.shade200,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(date)),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Shift Date: $date (4PM-4PM shift)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...history[date]!.map((record) {
                            final logs = List<Map<String, dynamic>>.from(record['logs']);
                            final totalDuration = calculateTotalDuration(logs);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: _getProfileImageUrl(record).isNotEmpty
                                      ? NetworkImage(_getProfileImageUrl(record))
                                      : null,
                                  child: _getProfileImageUrl(record).isEmpty
                                      ? Text(_getEmployeeName(record)[0])
                                      : null,
                                ),
                                title: Text(_getEmployeeName(record)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: getSectionColor(record['section'] ?? 'Unknown'),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Section: ${record['section'] ?? 'Unknown'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  buildLogList(logs),
                                ],
                              ),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatDuration(totalDuration),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    'Total Hours',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          }),
                        ],
                      ),
                    if (viewType != 'Daily')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Summary (Total Duration per Employee)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          ...summaryMap.entries.map((entry) {
                            return ListTile(
                              title: Text(entry.key),
                              trailing: Text(
                                formatDuration(entry.value),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                        ],
                      ),
                    if (viewType != 'Daily')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.blue.shade50,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$viewType Summary',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total working hours by employee',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...summaryMap.entries.map((entry) {
                            return ListTile(
                              title: Text(entry.key),
                              trailing: Text(
                                formatDuration(entry.value),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
