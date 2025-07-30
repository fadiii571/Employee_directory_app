import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

Future<void> generateAndSaveQRasPDF(String data) async {
  final status = await Permission.storage.request();
  if (!status.isGranted) {
    print("❌ Storage permission denied");
    return;
  }

  try {
    // Generate QR Code as image
    final qrValidationResult = QrValidator.validate(
      data: data,
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
          return pw.Center(
            child: pw.Image(qrImage, width: 200, height: 200),
          );
        },
      ),
    );

    // Save PDF
    final directory = await getExternalStorageDirectory();
    final pdfPath = "${directory!.path}/qr_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save());

    print("✅ QR code saved to PDF at: $pdfPath");
  } catch (e) {
    print("❌ Error generating/saving PDF: $e");
  }
}
