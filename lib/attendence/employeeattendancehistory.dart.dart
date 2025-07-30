import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/widgets/generatepdf.dart' show generateAttendancePdf;

class EmployeeQRDailyLogHistoryScreen extends StatefulWidget {
  const EmployeeQRDailyLogHistoryScreen({super.key});

  @override
  State<EmployeeQRDailyLogHistoryScreen> createState() => _EmployeeQRDailyLogHistoryScreenState();
}

class _EmployeeQRDailyLogHistoryScreenState extends State<EmployeeQRDailyLogHistoryScreen> {
  DateTime selectedDate = DateTime.now();

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

  Stream<QuerySnapshot> getAttendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(formattedDate)
        .collection('records')
        .snapshots();
  }

  Widget buildLogList(List logs) {
    if (logs.isEmpty) {
      return const Text("No logs");
    }

    logs.sort((a, b) {
      final timeA = DateFormat('hh:mm a').parse(a['time']);
      final timeB = DateFormat('hh:mm a').parse(b['time']);
      return timeA.compareTo(timeB);
    });

    final inLogs = logs.where((log) => log['type'] == 'In').map((log) => log['time']).toList();
    final outLogs = logs.where((log) => log['type'] == 'Out').map((log) => log['time']).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (inLogs.isNotEmpty)
          Text("In: ${inLogs.join(', ')}", style: const TextStyle(color: Colors.green)),
        if (outLogs.isNotEmpty)
          Text("Out: ${outLogs.join(', ')}", style: const TextStyle(color: Colors.red)),
      ],
    );
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
          IconButton(onPressed: ()async{
            await generateAttendancePdf(formattedDate);
          }, icon: Icon(Icons.picture_as_pdf))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Text("Selected Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(formattedDate),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getAttendanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text("No attendance data found for this date."));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final imageUrl = data['profileImageUrl'];
                    final logs = data['logs'] ?? [];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? Text(name.isNotEmpty ? name[0] : '?')
                            : null,
                      ),
                      title: Text(name),
                      subtitle: buildLogList(List<Map<String, dynamic>>.from(logs)),
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
