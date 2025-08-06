import 'dart:typed_data';
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

  DateTime _parseTime(String timeStr, DateTime fallbackDate) {
    try {
      final parsedTime = dateFormat.parse(timeStr);
      return DateTime(
        fallbackDate.year,
        fallbackDate.month,
        fallbackDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return fallbackDate;
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  pdf.addPage(
    pw.MultiPage(
      build: (context) {
        List<pw.Widget> content = [
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
        ];

        if (viewType == 'Daily') {
          for (final entry in logs) {
            final name = entry['name'] ?? '-';
            final rawLogs = List<Map<String, dynamic>>.from(entry['logs'] ?? []);
            final fallbackDate = DateTime.now(); // Adjust if needed

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
              final inTime = _parseTime(inLog['time'], fallbackDate);
              final outTime = _parseTime(outLog['time'], fallbackDate);
              workedDuration = outTime.difference(inTime);
            }

            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 14)),
                    pw.Text('Check In: $checkIns', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Check Out: $checkOuts', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Total Hours: ${formatDuration(workedDuration)}',
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.Divider(),
                  ],
                ),
              ),
            );
          }
        } else {
          // Weekly / Monthly: Show only name and total worked hours
          summary?.forEach((name, totalDuration) {
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(name, style: const pw.TextStyle(fontSize: 14)),
                    pw.Text('Total: $totalDuration', style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
          });
        }

        return content;
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
}

String calculateTotalDurationFormatted(List<Map<String, dynamic>> logs) {
  Duration total = Duration();

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
  return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
}
