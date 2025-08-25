
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

Future<void> generateAdvanceSlipPdf(String employeeName, double amount, DateTime date) async {
  final pdf = pw.Document();
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
  );

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 120 * PdfPageFormat.mm, marginAll: 5 * PdfPageFormat.mm),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.SizedBox(
                  height: 40,
                  width: 40,
                  child: pw.Image(logo),
                ),
                pw.SizedBox(width: 10),
                pw.Text('Advance Salary Slip', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 10),
            pw.Text('Date: ${DateFormat('dd-MM-yyyy').format(date)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('Employee Name: $employeeName', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('Advance Amount: Rs. ${amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Align(
             alignment: pw.Alignment.centerRight,
             child: pw.Text('Signature: _______________', style: const pw.TextStyle(fontSize: 10)),
            ),
            
          ],
        );
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/advance_slip.pdf");
  await file.writeAsBytes(await pdf.save());
  OpenFile.open(file.path);
}
