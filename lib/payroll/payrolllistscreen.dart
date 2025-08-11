import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollListScreen extends StatelessWidget {
  final String monthYear;

  const PayrollListScreen({super.key, required this.monthYear});

  @override
  Widget build(BuildContext context) {
    final payrollRef = FirebaseFirestore.instance
        .collection('payroll')
        .doc(monthYear)
        .collection('Employees');

    return Scaffold(
      appBar: AppBar(title: Text("Payroll for $monthYear")),
      body: StreamBuilder<QuerySnapshot>(
        stream: payrollRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No payroll data found"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Present: ${data['presentDays']}  |  Absent: ${data['absentDays']}"),
                      Text("Paid Leaves: ${data['paidLeaves']}  |  Sunday Leaves: ${data['sundayLeaves'] ?? 0}"),
                      Text("Total Leaves: ${data['totalLeaves'] ?? 0}  |  Working Days: ${data['workingDays']}"),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("₹${data['finalSalary'].toStringAsFixed(2)}"),
                      Text(data['status'], style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
