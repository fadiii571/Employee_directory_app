import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/services.dart';
import 'package:student_projectry_app/widgets/empattendencehis.dart';

class QRDailyAttendanceHistoryScreen extends StatefulWidget {
  const QRDailyAttendanceHistoryScreen({super.key});

  @override
  State<QRDailyAttendanceHistoryScreen> createState() => _QRDailyAttendanceHistoryScreenState();
}

class _QRDailyAttendanceHistoryScreenState extends State<QRDailyAttendanceHistoryScreen> {
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

  Stream<QuerySnapshot> getQRDailyAttendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .doc(formattedDate)
        .collection('records')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Attendance - Daily History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => pickDate(context),
            tooltip: 'Pick Date',
          ),
          IconButton(
  icon: const Icon(Icons.picture_as_pdf),
  onPressed: () async {
    final snapshot = await getQRDailyAttendance(date: formattedDate);
    await generateAttendancePdf(snapshot, formattedDate);
  },
  tooltip: 'Export to PDF',
)

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
              stream: getQRDailyAttendanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text("No QR attendance found for this date."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(data['profileImageUrl'] ?? ''),
                        child: (data['profileImageUrl'] == null) ? Text(data['name'][0]) : null,
                      ),
                      title: Text(data['name']),
                      subtitle: Text("Status: ${data['status']}"),
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
