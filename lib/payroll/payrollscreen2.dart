import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/services.dart';
import 'package:student_projectry_app/payroll/payrolldetailsc.dart';
import 'package:student_projectry_app/widgets/payrollpdf.dart'; // ensure generatePayrollForMonth is here

class GenerateAndViewPayrollScreen extends StatefulWidget {
  const GenerateAndViewPayrollScreen({super.key});

  @override
  State<GenerateAndViewPayrollScreen> createState() => _GenerateAndViewPayrollScreenState();
}

class _GenerateAndViewPayrollScreenState extends State<GenerateAndViewPayrollScreen> {
  DateTime selectedMonth = DateTime.now();
  bool isGenerating = false;

  Future<void> _generatePayroll() async {
    final monthYear = DateFormat('yyyy-MM').format(selectedMonth);
    setState(() => isGenerating = true);
    await generatePayrollForMonth(monthYear);
    setState(() => isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('yyyy-MM').format(selectedMonth);
    final payrollRef = FirebaseFirestore.instance
        .collection('payroll')
        .doc(monthYear)
        .collection('Employees');

    return Scaffold(
      appBar: AppBar(title: const Text("Generate & View Payroll"),
      actions: [
        IconButton(
    icon: const Icon(Icons.picture_as_pdf),
    onPressed: () async {
      final snapshot = await payrollRef.get();
      final records = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No payroll records to export.")),
        );
        return;
      }

      await generatePayrollPdf(monthYear, records);
    },
  ),
      ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(DateFormat('MMMM yyyy').format(selectedMonth), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedMonth,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                    helpText: 'Select Month',
                    fieldHintText: 'Month/Year',
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    setState(() => selectedMonth = picked);
                  }
                },
                child: const Text("Pick Month"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isGenerating ? null : _generatePayroll,
                child: isGenerating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Generate Payroll"),
              ),
            ],
          ),
          const Divider(thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: payrollRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text("No payroll data found for selected month"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
  title: Text(data['name'] ?? 'Unknown'),
 
  trailing: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text("₹${(data['finalSalary'] ?? 0).toStringAsFixed(2)}"),
      Text(data['status'] ?? '', style: const TextStyle(color: Colors.red)),
    ],
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayrollDetailScreen(payrollData: data),
      ),
    );
  },
),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
