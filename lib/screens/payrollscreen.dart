/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:student_projectry_app/Services/services.dart' show generatePayrollForMonth;

/// PayrollScreen shows monthly payroll, allows search/filter, summary totals,
/// mark‑as‑paid, and PDF salary‑slip download.
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  String _selectedMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      body: Column(
        children: [
          _buildTopControls(),
          _PayrollSummary(
            monthYear: _selectedMonthYear,
            searchQuery: _searchQuery,
          ),
          Expanded(
            child: _PayrollList(
              monthYear: _selectedMonthYear,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Month: ', style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: _selectedMonthYear,
                items: _buildMonthDropdown(),
                onChanged: (val) => setState(() => _selectedMonthYear = val!),
              ),
              const Spacer(),
              IconButton(
  icon: Icon(Icons.calculate),
  onPressed: () async {
    final now = DateTime.now();
    final formattedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await generatePayrollForMonth(formattedMonth);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payroll generated for $formattedMonth")),
    );
  },
),

            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search employee',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildMonthDropdown() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      final formatted = DateFormat('yyyy-MM').format(date);
      return DropdownMenuItem(
        value: formatted,
        child: Text(DateFormat('MMMM yyyy').format(date)),
      );
    });
  }
}

/// Summary card showing totals of base, deductions, final, etc.
class _PayrollSummary extends StatelessWidget {
  const _PayrollSummary({required this.monthYear, required this.searchQuery});

  final String monthYear;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payroll')
          .doc(monthYear)
          .collection('employees')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
        }
        final docs = snapshot.data!.docs;
        final filtered = docs.where((d) {
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        double totalBase = 0;
        double totalDeduction = 0;
        double totalFinal = 0;
        for (final d in filtered) {
          totalBase += (d['baseSalary'] ?? 0).toDouble();
          totalDeduction += (d['deduction'] ?? 0).toDouble();
          totalFinal += (d['finalSalary'] ?? 0).toDouble();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryTile('Total Base', totalBase),
                _summaryTile('Total Deduction', totalDeduction),
                _summaryTile('Total Final', totalFinal),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryTile(String label, double amount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Payroll list with search filter & PDF/Mark Paid actions.
class _PayrollList extends StatelessWidget {
  const _PayrollList({required this.monthYear, required this.searchQuery});

  final String monthYear;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payroll')
          .doc(monthYear)
          .collection('employees')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs.where((d) {
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No payroll data.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final payroll = d.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(payroll['name'] ?? 'Unnamed'),
                subtitle: Text(
                  'Salary: ₹${payroll['baseSalary']}  Final: ₹${payroll['finalSalary']}\n'
                  'Present: ${payroll['presentDays']}  Absent: ${payroll['absentDays']}  Leaves: ${payroll['paidLeaves']}',
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Download PDF',
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => _generateSalarySlipPdf(payroll, monthYear),
                    ),
                    payroll['status'] == 'Paid'
                        ? const Chip(label: Text('Paid', style: TextStyle(color: Colors.green)))
                        : ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('payroll')
                                  .doc(monthYear)
                                  .collection('employees')
                                  .doc(payroll['employeeId'])
                                  .update({'status': 'Paid'});
                            },
                            child: const Text('Mark Paid'),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Generates and opens a PDF salary slip for the given payroll map.
  Future<void> _generateSalarySlipPdf(Map<String, dynamic> payroll, String monthYear) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Salary Slip', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Text('Employee: ${payroll['name']}'),
                pw.Text('Employee ID: ${payroll['employeeId']}'),
                pw.Text('Month: $monthYear'),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _pdfRow('Base Salary', '₹${payroll['baseSalary']}'),
                    _pdfRow('Present Days', payroll['presentDays'].toString()),
                    _pdfRow('Paid Leaves', payroll['paidLeaves'].toString()),
                    _pdfRow('Absent Days', payroll['absentDays'].toString()),
                    _pdfRow('Deduction', '₹${payroll['deduction'].toStringAsFixed(2)}'),
                    _pdfRow('Net Pay', '₹${payroll['finalSalary'].toStringAsFixed(2)}'),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Status: ${payroll['status']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  pw.TableRow _pdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(label)),
        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(value)),
      ],
    );
  }
}*/

