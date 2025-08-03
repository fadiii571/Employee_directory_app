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
    logs.sort((a, b) {
      final timeA = DateFormat('hh:mm a').parse(a['time']);
      final timeB = DateFormat('hh:mm a').parse(b['time']);
      return timeA.compareTo(timeB);
    });

    final inLogs = logs.where((log) => log['type'] == 'In').toList();
    final outLogs = logs.where((log) => log['type'] == 'Out').toList();

    int count = min(inLogs.length, outLogs.length);
    Duration total = Duration.zero;

    for (int i = 0; i < count; i++) {
      final inTime = DateFormat('hh:mm a').parse(inLogs[i]['time']);
      final outTime = DateFormat('hh:mm a').parse(outLogs[i]['time']);
      total += outTime.difference(inTime);
    }

    return total;
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
              await generateAttendancePdf(title: "$viewType Attendance: ${formattedDate}", logs:currentVisibleLogs,viewType: viewType);
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

                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final records = history[date]!;

                    return Column(
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
                        ...records.map((record) {
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
