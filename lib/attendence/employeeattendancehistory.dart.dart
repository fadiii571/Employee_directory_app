import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/widgets/generatepdf.dart' show generateAttendancePdf;
import 'package:student_projectry_app/Services/services.dart';

class EmployeeQRDailyLogHistoryScreen extends StatefulWidget {
  const EmployeeQRDailyLogHistoryScreen({super.key});

  @override
  State<EmployeeQRDailyLogHistoryScreen> createState() =>
      _EmployeeQRDailyLogHistoryScreenState();
}

class _EmployeeQRDailyLogHistoryScreenState extends State<EmployeeQRDailyLogHistoryScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedSection = '';
  String viewType = 'Daily';
  List<Map<String, dynamic>> currentVisibleLogs = [];
  bool _isInitialized = false;

  // Available sections for filter
  final List<String> availableSections = [
    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish', 'Supervisors'
  ];

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

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
        setState(() {
          _isInitialized = true;
        });
        debugPrint('✅ Employee data preloaded for attendance history');
      } catch (e) {
        debugPrint('❌ Error preloading employee data: $e');
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
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                // View Type Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_view_day, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: viewType,
                        underline: const SizedBox(),
                        items: ['Daily', 'Weekly', 'Monthly']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => viewType = val);
                        },
                      ),
                    ],
                  ),
                ),
                // Section Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedSection.isNotEmpty ? selectedSection : '',
                        underline: const SizedBox(),
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
                          });
                        },
                      ),
                    ],
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
                selectedEmployeeId: '',
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

                            return ListTile(
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
