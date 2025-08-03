import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class EmployeeQrViewScreen extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeQrViewScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  Future<void> _generateAndSharePdf(BuildContext context) async {
    try {
      final qrPainter = QrPainter(
        data: employeeId,
        version: QrVersions.auto,
        gapless: false,
      );

      final image = await qrPainter.toImage(300);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final qrBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pwImage = pw.MemoryImage(qrBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Employee: $employeeName', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Image(pwImage, width: 200, height: 200),
              pw.SizedBox(height: 16),
              pw.Text('ID: $employeeId'),
            ],
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$employeeName-QR.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'QR Code for $employeeName');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR for $employeeName")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: employeeId,
              version: QrVersions.auto,
              size: 250,
            ),
            const SizedBox(height: 16),
            Text("Employee: $employeeName", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("ID: $employeeId", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.share),
              label: Text("Share QR as PDF"),
              onPressed: () => _generateAndSharePdf(context),
            ),
          ],
        ),
      ),
    );
  }
}
