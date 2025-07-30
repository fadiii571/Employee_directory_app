import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

Future<void> generateAttendancePdf(String date) async {
  final pdf = pw.Document();

  final snapshot = await FirebaseFirestore.instance
      .collection('attendance')
      .doc(date)
      .collection('records')
      .get();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Attendance Report - $date",
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Name', 'ID', 'In Time', 'Out Time'],
              data: snapshot.docs.map((doc) {
                final data = doc.data();
                final logs = data['logs'] as List<dynamic>;

                String inTime = '';
                String outTime = '';
                for (var log in logs) {
                  if (log['type'] == 'In') inTime = log['time'];
                  if (log['type'] == 'Out') outTime = log['time'];
                }

                return [
                  data['name'] ?? '',
                  data['id'] ?? '',
                  inTime,
                  outTime,
                ];
              }).toList(),
            )
          ],
        );
      },
    ),
  );

  // Save file
  final output = await getExternalStorageDirectory();
  final file = File("${output!.path}/Attendance-$date.pdf");
  await file.writeAsBytes(await pdf.save());

  // Optional: Preview or share
  await Printing.sharePdf(bytes: await pdf.save(), filename: 'Attendance-$date.pdf');
}
