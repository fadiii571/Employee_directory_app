import 'package:flutter/material.dart';

class PayrollDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payrollData;

  const PayrollDetailScreen({super.key, required this.payrollData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(payrollData['name'] ?? 'Payroll Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow("Employee Name", payrollData['name']),
            _infoRow("Working Days", payrollData['workingDays'].toString()),
            _infoRow("Present Days", payrollData['presentDays'].toString()),
            _infoRow("Absent Days", payrollData['absentDays'].toString()),
            _infoRow("Paid Leaves", payrollData['paidLeaves'].toString()),
            _infoRow("Deducted amount", "₹${(payrollData['deduction'] ?? 0).toStringAsFixed(2)}"),
            _infoRow("Final Salary", "₹${(payrollData['finalSalary'] ?? 0).toStringAsFixed(2)}"),
            _infoRow("Status", payrollData['status']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 5, child: Text(value ?? '')),
        ],
      ),
    );
  }
}
