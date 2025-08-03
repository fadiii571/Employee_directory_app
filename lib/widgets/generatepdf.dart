import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

Future<void> generateAttendancePdf({
  required String title,
  required List<Map<String, dynamic>> logs,
  String viewType = 'Daily',
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 16),
        pw.Table.fromTextArray(
          headers: [
            'Employee Name',
            'Check-In(s)',
            'Check-Out(s)',
            if (viewType == 'Daily') 'Total Hours',
          ],
          data: logs.map((record) {
            final name = record['name'] ?? 'Unknown';
            final logList = List<Map<String, dynamic>>.from(record['logs'] ?? []);

            logList.sort((a, b) {
              final timeA = DateFormat('hh:mm a').parse(a['time']);
              final timeB = DateFormat('hh:mm a').parse(b['time']);
              return timeA.compareTo(timeB);
            });

            final inLogs = logList
                .where((log) => log['type'] == 'In')
                .map((log) => log['time'])
                .join(', ');
            final outLogs = logList
                .where((log) => log['type'] == 'Out')
                .map((log) => log['time'])
                .join(', ');

            String total = '';
            if (viewType == 'Daily') {
              total = _calculateTotalDurationFormatted(logList);
            }

            return [
              name,
              inLogs,
              outLogs,
              if (viewType == 'Daily') total,
            ];
          }).toList(),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

/// Place this BELOW the above function
String _calculateTotalDurationFormatted(List<Map<String, dynamic>> logs) {
  logs.sort((a, b) {
    final timeA = DateFormat('hh:mm a').parse(a['time']);
    final timeB = DateFormat('hh:mm a').parse(b['time']);
    return timeA.compareTo(timeB);
  });

  final inLogs = logs.where((log) => log['type'] == 'In').toList();
  final outLogs = logs.where((log) => log['type'] == 'Out').toList();

  int count = inLogs.length < outLogs.length ? inLogs.length : outLogs.length;
  Duration total = Duration.zero;

  for (int i = 0; i < count; i++) {
    final inTime = DateFormat('hh:mm a').parse(inLogs[i]['time']);
    final outTime = DateFormat('hh:mm a').parse(outLogs[i]['time']);
    total += outTime.difference(inTime);
  }

  int hours = total.inHours;
  int minutes = total.inMinutes.remainder(60);

  return '${hours}h ${minutes}m';
}
