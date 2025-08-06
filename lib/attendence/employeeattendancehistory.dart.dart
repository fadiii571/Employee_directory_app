import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String selectedEmployeeId = '';
  String viewType = 'Daily';
  Map<String, String> employeeNames = {};
  List<Map<String, dynamic>> currentVisibleLogs = [];

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

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

  logs.sort((a, b) {
    final timeA = DateFormat('hh:mm a').parse(a['time']);
    final timeB = DateFormat('hh:mm a').parse(b['time']);
    return timeA.compareTo(timeB);
  });

  final inLogs = logs.where((log) => log['type'] == 'In').toList();
  final outLogs = logs.where((log) => log['type'] == 'Out').toList();

  final inTimes = inLogs.map((log) => log['time']).join(', ');
  final outTimes = outLogs.map((log) => log['time']).join(', ');

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
  if (logs.isEmpty) return Duration.zero;

  // Filter valid logs
  final inLog = logs.firstWhere(
    (log) => log['type'] == 'In' && log['time'] != null,
    orElse: () => <String, dynamic>{},
  );

  final outLog = logs.firstWhere(
    (log) => log['type'] == 'Out' && log['time'] != null,
    orElse: () => <String, dynamic>{},
  );

  final timeFormat = DateFormat('hh:mm a');

  try {
    final checkInTime = timeFormat.parse(inLog['time']);
    final checkOutTime = timeFormat.parse(outLog['time']);

    // ✅ Add one day if check-out is on next day (e.g., night shift)
    final adjustedOutTime = checkOutTime.isBefore(checkInTime)
        ? checkOutTime.add(Duration(days: 1))
        : checkOutTime;

    return adjustedOutTime.difference(checkInTime);
  } catch (e) {
    return Duration.zero;
  }
}


  String formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
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
              children: [
                DropdownButton<String>(
                  value: viewType,
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => viewType = val);
                  },
                ),
                if (employeeNames.isNotEmpty)
                  DropdownButton<String>(
                    value: selectedEmployeeId.isNotEmpty ? selectedEmployeeId : null,
                    hint: const Text("All Employees"),
                    items: employeeNames.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedEmployeeId = val ?? '');
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: fetchAttendanceHistory(
                selectedDate: selectedDate,
                viewType: viewType,
                selectedEmployeeId: selectedEmployeeId,
                employeeNames: employeeNames,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                            child: Text(
                              DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(date)),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...history[date]!.map((record) {
                            final logs = List<Map<String, dynamic>>.from(record['logs']);
                            final totalDuration = calculateTotalDuration(logs);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: (record['profileImageUrl'] as String).isNotEmpty
                                    ? NetworkImage(record['profileImageUrl'])
                                    : null,
                                child: (record['profileImageUrl'] as String).isEmpty
                                    ? Text(record['name'][0])
                                    : null,
                              ),
                              title: Text(record['name']),
                              subtitle: buildLogList(logs),
                              trailing: viewType == 'Daily'
                                  ? Text(formatDuration(totalDuration),
                                      style: const TextStyle(fontWeight: FontWeight.bold))
                                  : null,
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
                          }).toList(),
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
