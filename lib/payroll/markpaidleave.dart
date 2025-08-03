import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarkPaidLeaveScreen extends StatefulWidget {
  const MarkPaidLeaveScreen({super.key});

  @override
  State<MarkPaidLeaveScreen> createState() => _MarkPaidLeaveScreenState();
}

class _MarkPaidLeaveScreenState extends State<MarkPaidLeaveScreen> {
  List<Map<String, dynamic>> employees = [];

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    final snapshot = await FirebaseFirestore.instance.collection('Employees').get();
    setState(() {
      employees = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'] ?? 'Unknown',
              })
          .toList();
    });
  }

  Future<void> markPaidLeave(String employeeId, DateTime date, String reason) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);

    await FirebaseFirestore.instance
        .collection('paid_leaves')
        .doc(formatted)
        .collection('Employees')
        .doc(employeeId)
        .set({
      'reason': reason,
      'markedAt': FieldValue.serverTimestamp(),
    });
  }

  void showMarkLeaveDialog(String employeeId, String employeeName) {
    DateTime selectedDate = DateTime.now();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Mark Paid Leave for $employeeName"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    const Text("Date: "),
                    const SizedBox(width: 10),
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                          Navigator.of(context).pop();
                          showMarkLeaveDialog(employeeId, employeeName); // reopen with new date
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Mark Leave"),
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                await markPaidLeave(employeeId, selectedDate, reasonController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Paid leave marked for $employeeName')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Paid Leave')),
      body: employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final emp = employees[index];
                return ListTile(
                  title: Text(emp['name']),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => showMarkLeaveDialog(emp['id'], emp['name']),
                );
              },
            ),
    );
  }
}
