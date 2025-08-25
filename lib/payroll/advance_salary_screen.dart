
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/employee_service.dart';
import 'package:student_projectry_app/Services/payroll_service.dart';


class AdvanceSalaryScreen extends StatefulWidget {
  const AdvanceSalaryScreen({super.key});

  @override
  State<AdvanceSalaryScreen> createState() => _AdvanceSalaryScreenState();
}

class _AdvanceSalaryScreenState extends State<AdvanceSalaryScreen> {
  String? selectedEmployeeId;
  final TextEditingController _amountController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> allEmployees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await EmployeeService.getAllEmployeesWithStatus();
    setState(() {
      allEmployees = employees;
      isLoading = false;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Advance Salary'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: 'Select Employee',
                      border: OutlineInputBorder(),
                    ),
                    items: allEmployees.map((employee) {
                      return DropdownMenuItem<String>(
                        value: employee['id'],
                        child: Text(employee['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEmployeeId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Advance Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => _pickDate(context),
                        child: const Text('Change Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _giveAdvance,
                      child: const Text('Give Advance'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _giveAdvance() async {
    print('[_giveAdvance] button pressed');
    if (selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee.')),
      );
      print('[_giveAdvance] No employee selected.');
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      print('[_giveAdvance] Invalid amount entered: ${_amountController.text}');
      return;
    }
    final selectedEmployee = allEmployees.firstWhere((emp) => emp['id'] == selectedEmployeeId);
    final employeeName = selectedEmployee['name'];
    try {
      print('[_giveAdvance] Attempting to give advance to $employeeName for amount $amount on $selectedDate');
      await PayrollService.giveAdvanceSalary(
        employeeId: selectedEmployeeId!,
        employeeName: employeeName,
        amount: amount,
        date: selectedDate,
      );
      print('[_giveAdvance] PayrollService.giveAdvanceSalary successful.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Advance salary given successfully!')),
      );
      _amountController.clear();
      setState(() {
        selectedEmployeeId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to give advance: $e')),
      );
      print('[_giveAdvance] Error giving advance: $e');
    }
  }
}




