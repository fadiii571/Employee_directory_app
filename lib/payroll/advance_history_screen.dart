import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/widgets/advance_slip_pdf.dart';

/// A data model for an advance payment record.
/// Using a model class improves type safety and code readability.
class Advance {
  final String id;
  final String employeeName;
  final double amount;
  final DateTime date;

  Advance({
    required this.id,
    required this.employeeName,
    required this.amount,
    required this.date,
  });

  factory Advance.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Advance(
      id: doc.id,
      employeeName: data['employeeName'] ?? 'Unknown Employee',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}

class AdvanceHistoryScreen extends StatefulWidget {
  const AdvanceHistoryScreen({super.key});

  @override
  State<AdvanceHistoryScreen> createState() => _AdvanceHistoryScreenState();
}

class _AdvanceHistoryScreenState extends State<AdvanceHistoryScreen> {
  DateTime selectedMonth = DateTime.now();
  Stream<QuerySnapshot<Map<String, dynamic>>>? _advancesStream;

  @override
  void initState() {
    super.initState();
    _setStreamForSelectedMonth();
  }

  void _setStreamForSelectedMonth() {
    final monthYear = DateFormat('yyyy-MM').format(selectedMonth);
    _advancesStream = FirebaseFirestore.instance
        .collection('advances')
        .where('monthYear', isEqualTo: monthYear)
        .snapshots();
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = picked;
        _setStreamForSelectedMonth();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advance History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _pickMonth(context),
                  child: const Text('Select Month'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _advancesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No advance history for this month.'));
                }

                final advances = snapshot.data!.docs
                    .map((doc) => Advance.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: advances.length,
                  itemBuilder: (context, index) {
                    final advance = advances[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(advance.employeeName),
                        subtitle: Text(DateFormat('dd-MM-yyyy').format(advance.date)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${advance.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.picture_as_pdf, color: Colors.blue),
                              tooltip: 'Generate Advance Slip',
                              onPressed: () async {
                                try {
                                  await generateAdvanceSlipPdf(advance.employeeName, advance.amount, advance.date);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Advance slip generated!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to generate slip: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
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
