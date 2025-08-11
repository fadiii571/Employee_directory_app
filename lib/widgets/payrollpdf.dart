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
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Section', 'Base Salary', 'Present', 'Paid Leaves', 'Sunday Leaves', 'Absent', 'Working Days', 'Final Salary', 'Status'],
            data: data.map((e) => [
              e['name'] ?? '',
              e['section'] ?? '',
              'Rs.${e['baseSalary']?.toStringAsFixed(2) ?? '0'}',
              '${e['presentDays']?.toString() ?? '0'}/${e['workingDays']?.toString() ?? '0'}',
              e['paidLeaves']?.toString() ?? '0',
              e['sundayLeaves']?.toString() ?? '0',
              e['absentDays']?.toString() ?? '0',
              e['workingDays']?.toString() ?? '0',
              'Rs.${e['finalSalary']?.toStringAsFixed(2) ?? '0'}',
              e['status'] ?? '',
            ]).toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            "Note: Payroll calculated based on actual working days per month (Calendar days - Sundays). All Sundays are automatically counted as leave days.",
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
