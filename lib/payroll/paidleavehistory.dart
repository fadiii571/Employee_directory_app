import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_projectry_app/Services/services.dart';

class PaidLeaveHistoryScreen extends StatefulWidget {
  const PaidLeaveHistoryScreen({super.key});

  @override
  State<PaidLeaveHistoryScreen> createState() => _PaidLeaveHistoryScreenState();
}

class _PaidLeaveHistoryScreenState extends State<PaidLeaveHistoryScreen> {
  List<Map<String, dynamic>> leaveHistory = [];
  bool isLoading = false;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() => isLoading = true);
    leaveHistory = await fetchPaidLeaveHistory(startDate: startDate, endDate: endDate);
    setState(() => isLoading = false);
  }

  Future<void> selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Leave History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: selectDateRange,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaveHistory.isEmpty
              ? const Center(child: Text('No paid leaves found.'))
              : ListView.builder(
                  itemCount: leaveHistory.length,
                  itemBuilder: (context, index) {
                    final leave = leaveHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(leave['employeeName']),
                      subtitle: Text('Reason: ${leave['reason']}'),
                      trailing: Text(DateFormat('dd MMM yyyy').format(
                        DateFormat('yyyy-MM-dd').parse(leave['date']),
                      )),
                    );
                  },
                ),
    );
  }
}
