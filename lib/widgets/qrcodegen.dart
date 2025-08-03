import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// Request storage permission (Android 10+ safe)
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }
  return true; // iOS/macOS or not required
}

/// Generate and save QR Code as PDF
Future<void> saveQrCodeAsPdf({
  required String employeeId,
  required String employeeName,
  bool share = false,
}) async {
  final pdf = pw.Document();
  final qrImage = await QrPainter(
    data: employeeId,
    version: QrVersions.auto,
    gapless: false,
  ).toImage(300);
  final byteData = await qrImage.toByteData(format: ImageByteFormat.png);
  final qrBytes = byteData!.buffer.asUint8List();

  final image = pw.MemoryImage(qrBytes);

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Employee: $employeeName'),
            pw.SizedBox(height: 16),
            pw.Image(image, width: 200, height: 200),
            pw.SizedBox(height: 16),
            pw.Text('ID: $employeeId'),
          ],
        );
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/$employeeName-QR.pdf");
  await file.writeAsBytes(await pdf.save());

  if (share) {
    await Share.shareXFiles([XFile(file.path)], text: 'QR Code for $employeeName');
  }
}
