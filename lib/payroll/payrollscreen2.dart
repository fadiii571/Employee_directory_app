import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/payroll_service.dart';
import 'package:student_projectry_app/payroll/payrolldetailsc.dart';
import 'package:student_projectry_app/widgets/payrollpdf.dart';

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

    try {
      final result = await PayrollService.generatePayrollForMonth(monthYear);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']} - ${result['employeesProcessed']} employees processed'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generating payroll: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

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

                // Calculate summary statistics
                int paidCount = 0;
                int unpaidCount = 0;
                double totalPaidAmount = 0;
                double totalUnpaidAmount = 0;

                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Unpaid';
                  final salary = (data['finalSalary'] ?? 0).toDouble();

                  if (status == 'Paid') {
                    paidCount++;
                    totalPaidAmount += salary;
                  } else {
                    unpaidCount++;
                    totalUnpaidAmount += salary;
                  }
                }

                return Column(
                  children: [
                    // Responsive Summary Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.green.withValues(alpha: 0.05),
                              elevation: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'PAID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$paidCount emp',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rs.${totalPaidAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Card(
                              color: Colors.red.withValues(alpha: 0.05),
                              elevation: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'UNPAID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$unpaidCount emp',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rs.${totalUnpaidAmount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Employee List
                    Expanded(
                      child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Responsive employee info layout
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 350) {
                                  // Vertical layout for very small screens
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              data['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (data['status'] ?? '') == 'Paid' ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              data['status'] ?? 'Unpaid',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹${(data['finalSalary'] ?? 0).toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Present: ${data['presentDays']}/30 | Leaves: ${data['paidLeaves']} | Absent: ${data['absentDays']}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Horizontal layout for larger screens
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Present: ${data['presentDays']}/30 | Leaves: ${data['paidLeaves']} | Absent: ${data['absentDays']}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₹${(data['finalSalary'] ?? 0).toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (data['status'] ?? '') == 'Paid' ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              data['status'] ?? 'Unpaid',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            // Mobile-responsive button layout
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // For very small screens, stack buttons vertically
                                if (constraints.maxWidth < 350) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                await PayrollService.updatePayrollStatus(
                                                  monthYear: monthYear,
                                                  employeeId: docs[index].id,
                                                  status: 'Paid'
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('✅ Marked ${data['name']} as Paid')),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.check_circle, size: 14),
                                              label: const Text('Paid', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                minimumSize: const Size(0, 32),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                await PayrollService.updatePayrollStatus(
                                                  monthYear: monthYear,
                                                  employeeId: docs[index].id,
                                                  status: 'Unpaid'
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('❌ Marked ${data['name']} as Unpaid')),
                                                  );
                                                }
                                              },
                                              icon: const Icon(Icons.cancel, size: 14),
                                              label: const Text('Unpaid', style: TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                                minimumSize: const Size(0, 32),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PayrollDetailScreen(payrollData: data),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.visibility, size: 14),
                                          label: const Text('View Details', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                            minimumSize: const Size(0, 32),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // For larger screens, use horizontal layout
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            await PayrollService.updatePayrollStatus(
                                              monthYear: monthYear,
                                              employeeId: docs[index].id,
                                              status: 'Paid'
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('✅ Marked ${data['name']} as Paid')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.check_circle, size: 16),
                                          label: const Text('Paid', style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            minimumSize: const Size(0, 36),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            await PayrollService.updatePayrollStatus(
                                              monthYear: monthYear,
                                              employeeId: docs[index].id,
                                              status: 'Unpaid'
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('❌ Marked ${data['name']} as Unpaid')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.cancel, size: 16),
                                          label: const Text('Unpaid', style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            minimumSize: const Size(0, 36),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PayrollDetailScreen(payrollData: data),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.visibility, size: 16),
                                          label: const Text('View', style: TextStyle(fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                            minimumSize: const Size(0, 36),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
