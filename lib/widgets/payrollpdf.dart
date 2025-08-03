import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

Future<void> generatePayrollPdf(String month, List<Map<String, dynamic>> data) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return [
          pw.Text("Payroll for $month", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Name', 'Salary', 'Present', 'Absent', 'Leaves', 'Status'],
            data: data.map((e) => [
              e['name'] ?? '',
              '₹${e['finalSalary']?.toStringAsFixed(2) ?? '0'}',
              e['presentDays']?.toString() ?? '0',
              e['absentDays']?.toString() ?? '0',
              e['paidLeaves']?.toString() ?? '0',
              e['status'] ?? '',
            ]).toList(),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
