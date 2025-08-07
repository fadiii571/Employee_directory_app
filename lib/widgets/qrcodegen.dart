import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

/// Enhanced QR Code Generator with validation and clean design
class QRCodeGenerator {
  /// Generate a valid QR code data string for employee
  static String generateEmployeeQRData({
    required String employeeId,
    required String employeeName,
    String? section,
  }) {
    // Create a structured format for better validation and parsing
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanId = employeeId.trim();
    final cleanName = employeeName.trim();
    final cleanSection = section?.trim() ?? 'Unknown';

    // Format: EMP:ID|NAME|SECTION|TIMESTAMP
    return 'EMP:$cleanId|$cleanName|$cleanSection|$timestamp';
  }

  /// Validate QR code data format
  static bool isValidEmployeeQR(String qrData) {
    if (qrData.isEmpty) return false;

    // Check structured format
    if (qrData.startsWith('EMP:')) {
      final parts = qrData.substring(4).split('|');
      return parts.length >= 3 && parts[0].isNotEmpty;
    }

    // Accept simple employee ID for backward compatibility
    return qrData.trim().isNotEmpty && qrData.length >= 3;
  }

  /// Extract employee ID from QR data
  static String extractEmployeeId(String qrData) {
    if (qrData.startsWith('EMP:')) {
      final parts = qrData.substring(4).split('|');
      return parts.isNotEmpty ? parts[0] : qrData;
    }
    return qrData.trim();
  }

  /// Extract employee name from QR data
  static String? extractEmployeeName(String qrData) {
    if (qrData.startsWith('EMP:')) {
      final parts = qrData.substring(4).split('|');
      return parts.length >= 2 ? parts[1] : null;
    }
    return null;
  }

  /// Extract section from QR data
  static String? extractSection(String qrData) {
    if (qrData.startsWith('EMP:')) {
      final parts = qrData.substring(4).split('|');
      return parts.length >= 3 ? parts[2] : null;
    }
    return null;
  }
}

/// Generate and save QR Code as PDF with enhanced design
Future<void> saveQrCodeAsPdf({
  required String employeeId,
  required String employeeName,
  String? section,
  bool share = false,
}) async {
  try {
    // Generate enhanced QR data
    final qrData = QRCodeGenerator.generateEmployeeQRData(
      employeeId: employeeId,
      employeeName: employeeName,
      section: section,
    );

    // Create QR code image
    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
      errorCorrectionLevel: QrErrorCorrectLevel.M, // Medium error correction
    );

    final qrImage = await qrPainter.toImage(400); // Higher resolution
    final byteData = await qrImage.toByteData(format: ImageByteFormat.png);
    final qrBytes = byteData!.buffer.asUint8List();
    final image = pw.MemoryImage(qrBytes);

    // Create professional PDF
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'EMPLOYEE QR CODE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Student Project App - Attendance System',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Employee Info
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Employee: $employeeName',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('ID: $employeeId', style: const pw.TextStyle(fontSize: 14)),
                    if (section != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text('Section: $section', style: const pw.TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // QR Code
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Image(image, width: 250, height: 250),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Scan this QR code for attendance',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Footer
              pw.Text(
                'Generated on $dateStr',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    // Save file
    final output = await getTemporaryDirectory();
    final fileName = '${employeeName.replaceAll(' ', '_')}_QR_Code.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Share if requested
    if (share) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code for $employeeName - Employee ID: $employeeId',
      );
    }
  } catch (e) {
    throw Exception('Failed to generate QR PDF: $e');
  }
}

/// Clean QR Code Widget for displaying QR codes in the app
class CleanQRCodeWidget extends StatelessWidget {
  final String employeeId;
  final String employeeName;
  final String? section;
  final double size;
  final bool showEmployeeInfo;

  const CleanQRCodeWidget({
    Key? key,
    required this.employeeId,
    required this.employeeName,
    this.section,
    this.size = 200.0,
    this.showEmployeeInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate valid QR data
    final qrData = QRCodeGenerator.generateEmployeeQRData(
      employeeId: employeeId,
      employeeName: employeeName,
      section: section,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showEmployeeInfo) ...[
            Text(
              employeeName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $employeeId',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (section != null) ...[
              const SizedBox(height: 4),
              Text(
                'Section: $section',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],

          // QR Code with border
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: size,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          if (showEmployeeInfo) ...[
            const SizedBox(height: 12),
            Text(
              'Scan for attendance',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple function for backward compatibility (legacy support)
Future<void> generateQrCodePdf({
  required String employeeId,
  required String employeeName,
  bool share = false,
}) async {
  await saveQrCodeAsPdf(
    employeeId: employeeId,
    employeeName: employeeName,
    section: null,
    share: share,
  );
}
