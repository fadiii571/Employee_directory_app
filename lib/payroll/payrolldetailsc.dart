import 'package:flutter/material.dart';

class PayrollDetailScreen extends StatelessWidget {
  final Map<String, dynamic> payrollData;

  const PayrollDetailScreen({super.key, required this.payrollData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(payrollData['name'] ?? 'Payroll Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Employee Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow("Employee Name", payrollData['name']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Salary Calculation Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Salary Calculation",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow("Base Salary", "₹${(payrollData['baseSalary'] ?? 0).toStringAsFixed(2)}"),
                    _infoRow("Advance Salary", "₹${(payrollData['advanceSalary'] ?? 0).toStringAsFixed(2)}"),
                    const Divider(),
                    _infoRow(
                      "Final Salary",
                      "₹${(payrollData['finalSalary'] ?? 0).toStringAsFixed(2)}",
                      isHighlighted: true,
                    ),
                    _infoRow("Status", payrollData['status'], isStatus: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Calculation Note
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Calculation Details",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "• Final Salary = Base Salary - Advance Salary",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Add bottom spacing to prevent overflow
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String? value, {bool isHighlighted = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Colors.green[800] : null,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value ?? '',
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted
                    ? Colors.green[800]
                    : isStatus
                        ? (value == 'Paid' ? Colors.green : Colors.red)
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
