import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';


Future<void> saveQrCodeAsPdf({
  required String employeeId,
  required String employeeName,
}) async {
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    print("❌ Storage permission denied");
    return;
  }

  try {
    // Generate QR code from employee ID
    final qrValidationResult = QrValidator.validate(
      data: employeeId,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
    final qrCode = qrValidationResult.qrCode;

    final painter = QrPainter.withQr(
      qr: qrCode!,
      color: Colors.black,
      emptyColor: Colors.white,
      gapless: true,
    );

    final image = await painter.toImage(300);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Create PDF
    final pdf = pw.Document();
    final qrImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Employee Name: $employeeName',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Image(qrImage, width: 200, height: 200),
              pw.SizedBox(height: 10),
              pw.Text('Employee ID: $employeeId'),
            ],
          );
        },
      ),
    );

    // Save PDF to Downloads
    final directory = Directory('/storage/emulated/0/Download');
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final fileName = 'qr_${employeeName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = '${directory.path}/$fileName';
    final pdfFile = File(pdfPath);

    await pdfFile.writeAsBytes(await pdf.save());

    print("✅ PDF saved to: $pdfPath");

    // Optional: open the PDF
    await OpenFile.open(pdfPath);
  } catch (e) {
    print("❌ Error saving QR as PDF: $e");
  }
}
