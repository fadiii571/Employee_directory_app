import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateAttendancePdf({
  required String title,
  required List<Map<String, dynamic>> logs,
  required String viewType, // 'Daily', 'Weekly', 'Monthly'
  Map<String, String>? summary, // Used for Weekly/Monthly view
}) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('hh:mm a');

  // Helper functions
  DateTime parseTime(String timeStr) {
    try {
      final parsedTime = dateFormat.parse(timeStr);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (_) {
      return DateTime.now();
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Build the PDF content
  if (viewType == 'Daily') {
    // Daily Report with Table
    final tableData = <List<String>>[];

    for (final entry in logs) {
      final name = entry['name'] ?? '-';
      final section = entry['section'] ?? 'Unknown';
      final rawLogs = List<Map<String, dynamic>>.from(entry['logs'] ?? []);

      final checkIns = rawLogs
          .where((e) => e['type'] == 'In')
          .map((e) => e['time'] ?? '-')
          .join(', ');

      final checkOuts = rawLogs
          .where((e) => e['type'] == 'Out')
          .map((e) => e['time'] ?? '-')
          .join(', ');

      Duration workedDuration = Duration.zero;
      final inLog = rawLogs.firstWhere((e) => e['type'] == 'In', orElse: () => {});
      final outLog = rawLogs.firstWhere((e) => e['type'] == 'Out', orElse: () => {});

      if (inLog.isNotEmpty && outLog.isNotEmpty) {
        final inTime = parseTime(inLog['time']);
        final outTime = parseTime(outLog['time']);
        workedDuration = outTime.difference(inTime);
      }

      final status = checkIns.isNotEmpty && checkOuts.isNotEmpty ? 'Complete' :
                    checkIns.isNotEmpty ? 'In Progress' : 'Absent';

      tableData.add([
        name,
        section,
        checkIns.isEmpty ? '-' : checkIns,
        checkOuts.isEmpty ? '-' : checkOuts,
        formatDuration(workedDuration),
        status,
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 20),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ATTENDANCE REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                title,
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Student Project App - Attendance System',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Page ${context.pageNumber}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Text(
            'Daily Attendance Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headers: ['Employee Name', 'Section', 'Check In', 'Check Out', 'Total Hours', 'Status'],
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            cellDecoration: (index, data, rowNum) {
              return pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
              );
            },
          ),
          pw.SizedBox(height: 30),
          // Summary Statistics
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      '${logs.length}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Total Employees', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${logs.where((log) {
                        final rawLogs = List<Map<String, dynamic>>.from(log['logs'] ?? []);
                        return rawLogs.any((l) => l['type'] == 'In');
                      }).length}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Present', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text(
                      '${logs.length - logs.where((log) {
                        final rawLogs = List<Map<String, dynamic>>.from(log['logs'] ?? []);
                        return rawLogs.any((l) => l['type'] == 'In');
                      }).length}',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Absent', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } else {
    // Summary Report for Weekly/Monthly
    final tableData = summary?.entries.map((entry) => [entry.key, entry.value]).toList() ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ATTENDANCE SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated on ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              '$viewType Summary Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              headers: ['Employee Name', 'Total Hours'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 12),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              cellDecoration: (index, data, rowNum) {
                return pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                );
              },
            ),
          ],
        ),
      ),
    );
  }







  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

// Helper functions for backward compatibility
String calculateTotalDurationFormatted(List<Map<String, dynamic>> logs) {
  Duration total = Duration.zero;

  final ins = logs.where((log) => log['type'] == 'In').toList();
  final outs = logs.where((log) => log['type'] == 'Out').toList();

  int pairs = ins.length < outs.length ? ins.length : outs.length;

  for (int i = 0; i < pairs; i++) {
    try {
      final inTime = parseTimeString(logs[i * 2]['time']);
      final outTime = parseTimeString(logs[i * 2 + 1]['time']);
      total += outTime.difference(inTime);
    } catch (_) {
      continue;
    }
  }

  return formatDuration(total);
}

DateTime parseTimeString(String timeStr) {
  final now = DateTime.now();
  final parsedTime = DateFormat('hh:mm a').parse(timeStr);
  return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}
