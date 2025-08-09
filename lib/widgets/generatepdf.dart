import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_projectry_app/Services/section_shift_helper.dart';


Future<void> generateAttendancePdf({
  required String title,
  required List<Map<String, dynamic>> logs,
  required String viewType, // 'Daily', 'Weekly', 'Monthly'
  Map<String, String>? summary, // Used for Weekly/Monthly view
}) async {
  final pdf = pw.Document();

  // Helper functions
  DateTime parseTime(String timeStr) {
    if (timeStr.isEmpty) return DateTime.now();

    // List of possible time formats (same as attendance history)
    final formats = [
      DateFormat('hh:mm a'),    // 03:01 AM
      DateFormat('HH:mm'),      // 03:01 (24-hour)
      DateFormat('h:mm a'),     // 3:01 AM
      DateFormat('H:mm'),       // 3:01 (24-hour)
      DateFormat('hh:mm'),      // 03:01 (12-hour without AM/PM)
    ];

    for (final format in formats) {
      try {
        final parsedTime = format.parse(timeStr);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
      } catch (e) {
        // Try next format
        continue;
      }
    }

    // If all parsing fails, return current time
    return DateTime.now();
  }

  // Format time to 12-hour format for PDF display
  String formatTimeTo12Hour(dynamic timeValue) {
    if (timeValue == null) return '-';

    final timeStr = timeValue.toString().trim();
    if (timeStr.isEmpty) return '-';

    // If already in 12-hour format, return as is
    if (timeStr.toLowerCase().contains('am') || timeStr.toLowerCase().contains('pm')) {
      return timeStr;
    }

    // Parse the time and convert to 12-hour format
    try {
      final parsedTime = parseTime(timeStr);
      return DateFormat('h:mm a').format(parsedTime);
    } catch (e) {
      return timeStr; // Return original if parsing fails
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Check if the attendance type represents a check-in
  bool isCheckInType(dynamic type) {
    if (type == null) return false;
    final typeStr = type.toString().toLowerCase().trim();
    return typeStr == 'check in' || typeStr == 'in' || typeStr == 'checkin';
  }

  // Check if the attendance type represents a check-out
  bool isCheckOutType(dynamic type) {
    if (type == null) return false;
    final typeStr = type.toString().toLowerCase().trim();
    return typeStr == 'check out' || typeStr == 'out' || typeStr == 'checkout';
  }

  // Calculate total duration for PDF (same logic as attendance history)
  Duration calculatePDFDuration(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return Duration.zero;

    // Find check-in and check-out logs (handle both old and new formats)
    final checkInLog = logs.firstWhere(
      (log) => isCheckInType(log['type']) && log['time'] != null,
      orElse: () => <String, dynamic>{},
    );

    final checkOutLog = logs.firstWhere(
      (log) => isCheckOutType(log['type']) && log['time'] != null,
      orElse: () => <String, dynamic>{},
    );

    // If either check-in or check-out is missing, return zero
    if (checkInLog.isEmpty || checkOutLog.isEmpty) {
      return Duration.zero;
    }

    try {
      final checkInTime = parseTime(checkInLog['time']);
      final checkOutTime = parseTime(checkOutLog['time']);

      // Handle cross-day scenarios (same logic as attendance history)
      if (checkOutTime.isBefore(checkInTime)) {
        // Check-out is next day
        final nextDayCheckOut = checkOutTime.add(const Duration(days: 1));
        final duration = nextDayCheckOut.difference(checkInTime);
        return duration.isNegative ? Duration.zero : duration;
      } else {
        // Same day check-in and check-out
        final duration = checkOutTime.difference(checkInTime);
        return duration.isNegative ? Duration.zero : duration;
      }
    } catch (e) {
      return Duration.zero;
    }
  }



  // Convert time to 24-hour format (HH:mm) for punctuality calculation
  String convertTo24HourFormat(String timeStr) {
    try {
      final parsedTime = parseTime(timeStr);
      return DateFormat('HH:mm').format(parsedTime);
    } catch (e) {

      return timeStr; // Return original if conversion fails
    }
  }

  // Helper function to determine punctuality status using section shift configuration
  // NOTE: This only affects PDF punctuality display, not attendance marking logic
  String getPunctualityStatus(String? checkInTime, String section) {
    if (checkInTime == null || checkInTime.isEmpty || checkInTime == '-') {
      return 'Absent';
    }

    // Convert time to 24-hour format for SectionShiftHelper
    String timeIn24HourFormat = convertTo24HourFormat(checkInTime);

    // Use section shift helper for accurate punctuality calculation in PDF reports
    final punctualityResult = SectionShiftHelper.calculatePunctualityStatus(timeIn24HourFormat, section);



    return punctualityResult;
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
          .where((e) => isCheckInType(e['type']))
          .map((e) => formatTimeTo12Hour(e['time']))
          .join(', ');

      final checkOuts = rawLogs
          .where((e) => isCheckOutType(e['type']))
          .map((e) => formatTimeTo12Hour(e['time']))
          .join(', ');

      // Use the same duration calculation logic as attendance history
      Duration workedDuration = calculatePDFDuration(rawLogs);

      final status = checkIns.isNotEmpty && checkOuts.isNotEmpty ? 'Complete' :
                    checkIns.isNotEmpty ? 'In Progress' : 'Absent';

      // Determine punctuality status
      String punctuality = 'Absent';
      if (checkIns.isNotEmpty && checkIns != '-') {
        // Find check-in log - handle different type formats
        final firstCheckIn = rawLogs.firstWhere(
          (e) => isCheckInType(e['type']),
          orElse: () => {}
        );
        if (firstCheckIn.isNotEmpty) {
          punctuality = getPunctualityStatus(firstCheckIn['time'], section);
        }
      }

      tableData.add([
        name,
        section,
        checkIns.isEmpty ? '-' : checkIns,
        checkOuts.isEmpty ? '-' : checkOuts,
        formatDuration(workedDuration),
        status,
        punctuality, // New punctuality column
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
          _buildColoredAttendanceTable(tableData),
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
            pw.TableHelper.fromTextArray(
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

// Helper function to build colored attendance table
pw.Widget _buildColoredAttendanceTable(List<List<dynamic>> tableData) {
  final headers = ['Employee Name', 'Section', 'Check In', 'Check Out', 'Total Hours', 'Status', 'Punctuality'];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(2.0), // Employee Name
      1: const pw.FlexColumnWidth(1.2), // Section
      2: const pw.FlexColumnWidth(1.2), // Check In
      3: const pw.FlexColumnWidth(1.2), // Check Out
      4: const pw.FlexColumnWidth(1.2), // Total Hours
      5: const pw.FlexColumnWidth(1.2), // Status
      6: const pw.FlexColumnWidth(1.0), // Punctuality
    },
    children: [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: headers.map((header) => pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            header,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        )).toList(),
      ),
      // Data rows
      ...tableData.map((row) {
        return pw.TableRow(
          children: row.asMap().entries.map((entry) {
            final index = entry.key;
            final cellData = entry.value.toString();

            // Special styling for punctuality column (index 6)
            if (index == 6) {
              PdfColor backgroundColor = PdfColors.white;
              PdfColor textColor = PdfColors.black;

              switch (cellData) {
                case 'Early':
                  backgroundColor = PdfColors.green100;
                  textColor = PdfColors.green800;
                  break;
                case 'On Time':
                  backgroundColor = PdfColors.orange100;
                  textColor = PdfColors.orange800;
                  break;
                case 'Late':
                  backgroundColor = PdfColors.red100;
                  textColor = PdfColors.red800;
                  break;
              }

              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(color: backgroundColor),
                child: pw.Text(
                  cellData,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: textColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
            }

            // Regular cell styling for other columns
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                cellData,
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
        );
      }),
    ],
  );
}

// Helper functions for backward compatibility
String calculateTotalDurationFormatted(List<Map<String, dynamic>> logs) {
  if (logs.isEmpty) return '0h 0m';

  // Find check-in and check-out logs (handle both old and new formats)
  final checkInLog = logs.firstWhere(
    (log) {
      if (log['time'] == null) return false;
      final type = log['type']?.toString().toLowerCase().trim();
      return type == 'check in' || type == 'in';
    },
    orElse: () => <String, dynamic>{},
  );

  final checkOutLog = logs.firstWhere(
    (log) {
      if (log['time'] == null) return false;
      final type = log['type']?.toString().toLowerCase().trim();
      return type == 'check out' || type == 'out';
    },
    orElse: () => <String, dynamic>{},
  );

  // If either check-in or check-out is missing, return zero
  if (checkInLog.isEmpty || checkOutLog.isEmpty) {
    return '0h 0m';
  }

  try {
    final checkInTime = parseTimeString(checkInLog['time']);
    final checkOutTime = parseTimeString(checkOutLog['time']);

    // Handle cross-day scenarios
    Duration totalDuration;
    if (checkOutTime.isBefore(checkInTime)) {
      // Check-out is next day
      final nextDayCheckOut = checkOutTime.add(const Duration(days: 1));
      totalDuration = nextDayCheckOut.difference(checkInTime);
    } else {
      // Same day check-in and check-out
      totalDuration = checkOutTime.difference(checkInTime);
    }

    // Ensure we don't return negative duration
    totalDuration = totalDuration.isNegative ? Duration.zero : totalDuration;
    return formatDuration(totalDuration);
  } catch (e) {
    return '0h 0m';
  }
}

DateTime parseTimeString(String timeStr) {
  if (timeStr.isEmpty) return DateTime.now();

  // List of possible time formats (same as main parseTime function)
  final formats = [
    DateFormat('hh:mm a'),    // 03:01 AM
    DateFormat('HH:mm'),      // 03:01 (24-hour)
    DateFormat('h:mm a'),     // 3:01 AM
    DateFormat('H:mm'),       // 3:01 (24-hour)
    DateFormat('hh:mm'),      // 03:01 (12-hour without AM/PM)
  ];

  for (final format in formats) {
    try {
      final parsedTime = format.parse(timeStr);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      // Try next format
      continue;
    }
  }

  // If all parsing fails, return current time
  return DateTime.now();
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}m';
}
