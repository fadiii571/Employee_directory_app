import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Services/shift_rotation_service.dart';
import '../Services/employee_service.dart';

/// Admin Office Shift Rotation Management Screen
/// 
/// Allows admin to:
/// - Set up alternating shifts for 2 Admin Office employees
/// - View current rotation schedule
/// - Enable/disable rotation
/// - Switch rotation order
class AdminOfficeShiftRotationScreen extends StatefulWidget {
  const AdminOfficeShiftRotationScreen({super.key});

  @override
  State<AdminOfficeShiftRotationScreen> createState() => _AdminOfficeShiftRotationScreenState();
}

class _AdminOfficeShiftRotationScreenState extends State<AdminOfficeShiftRotationScreen> {
  
  // State variables
  List<Map<String, dynamic>> adminOfficeEmployees = [];
  Map<String, dynamic>? currentRotation;
  Map<String, Map<String, dynamic>> schedulePreview = {};
  
  String? selectedEmployee1;
  String? selectedEmployee2;
  DateTime startDate = DateTime.now();
  bool employee1StartsFirst = true;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  /// Load Admin Office employees and current rotation
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Load Admin Office employees
      final employees = await EmployeeService.getEmployeesBySection('Admin office');
      
      // Load current rotation
      final rotation = await ShiftRotationService.getCurrentRotation();
      
      setState(() {
        adminOfficeEmployees = employees;
        currentRotation = rotation;
        
        // Pre-select employees if rotation exists
        if (rotation != null) {
          selectedEmployee1 = rotation['employee1Id'];
          selectedEmployee2 = rotation['employee2Id'];
          startDate = DateTime.parse(rotation['startDate']);
          employee1StartsFirst = rotation['employee1StartsFirst'] ?? true;
        }
      });
      
      // Load schedule preview
      await _loadSchedulePreview();
      
    } catch (e) {
      _showMessage('Error loading data: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  /// Load schedule preview for next 14 days
  Future<void> _loadSchedulePreview() async {
    if (currentRotation != null && currentRotation!['isActive'] == true) {
      final endDate = DateTime.now().add(const Duration(days: 14));
      final schedule = await ShiftRotationService.getRotationSchedule(
        startDate: DateTime.now(),
        endDate: endDate,
      );
      
      setState(() {
        schedulePreview = schedule;
      });
    }
  }
  
  /// Set up new shift rotation
  Future<void> _setupRotation() async {
    if (selectedEmployee1 == null || selectedEmployee2 == null) {
      _showMessage('Please select both employees', isError: true);
      return;
    }
    
    if (selectedEmployee1 == selectedEmployee2) {
      _showMessage('Please select different employees', isError: true);
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final result = await ShiftRotationService.setupShiftRotation(
        employee1Id: selectedEmployee1!,
        employee2Id: selectedEmployee2!,
        startDate: startDate,
        employee1StartsFirst: employee1StartsFirst,
      );
      
      if (result['success']) {
        _showMessage(result['message']);
        await _loadData(); // Refresh data
      } else {
        _showMessage(result['message'], isError: true);
      }
      
    } catch (e) {
      _showMessage('Error setting up rotation: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  /// Toggle rotation active status
  Future<void> _toggleRotation(bool isActive) async {
    setState(() => isLoading = true);
    
    try {
      final result = await ShiftRotationService.updateRotation(isActive: isActive);
      
      if (result['success']) {
        _showMessage(result['message']);
        await _loadData(); // Refresh data
      } else {
        _showMessage(result['message'], isError: true);
      }
      
    } catch (e) {
      _showMessage('Error updating rotation: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  /// Switch rotation order
  Future<void> _switchRotationOrder() async {
    setState(() => isLoading = true);
    
    try {
      final newOrder = !(currentRotation?['employee1StartsFirst'] ?? true);
      final result = await ShiftRotationService.updateRotation(employee1StartsFirst: newOrder);
      
      if (result['success']) {
        _showMessage('Rotation order switched successfully');
        await _loadData(); // Refresh data
      } else {
        _showMessage(result['message'], isError: true);
      }
      
    } catch (e) {
      _showMessage('Error switching rotation: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  /// Show message to user
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Pick start date
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Office Shift Rotation'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentRotationCard(),
                  const SizedBox(height: 20),
                  _buildSetupRotationCard(),
                  const SizedBox(height: 20),
                  _buildSchedulePreviewCard(),
                ],
              ),
            ),
    );
  }
  
  /// Build current rotation status card
  Widget _buildCurrentRotationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Current Rotation Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (currentRotation == null) ...[
              const Text(
                'No shift rotation configured',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ] else ...[
              _buildRotationInfo(),
              const SizedBox(height: 16),
              _buildRotationControls(),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Build rotation information
  Widget _buildRotationInfo() {
    final isActive = currentRotation!['isActive'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: isActive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Employee 1: ${currentRotation!['employee1Name']}'),
        Text('Employee 2: ${currentRotation!['employee2Name']}'),
        Text('Start Date: ${currentRotation!['startDate']}'),
        Text('Current Order: ${currentRotation!['employee1Name']} starts first'),
      ],
    );
  }
  
  /// Build rotation control buttons
  Widget _buildRotationControls() {
    final isActive = currentRotation!['isActive'] == true;
    
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _toggleRotation(!isActive),
          icon: Icon(isActive ? Icons.pause : Icons.play_arrow),
          label: Text(isActive ? 'Disable' : 'Enable'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _switchRotationOrder,
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Switch Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  /// Build setup rotation card
  Widget _buildSetupRotationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Setup New Rotation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Employee selection
            Text('Select Admin Office Employees:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              value: selectedEmployee1,
              decoration: const InputDecoration(
                labelText: 'Employee 1',
                border: OutlineInputBorder(),
              ),
              items: adminOfficeEmployees.map((emp) {
                return DropdownMenuItem(
                  value: emp['id'],
                  child: Text(emp['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedEmployee1 = value),
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: selectedEmployee2,
              decoration: const InputDecoration(
                labelText: 'Employee 2',
                border: OutlineInputBorder(),
              ),
              items: adminOfficeEmployees.map((emp) {
                return DropdownMenuItem(
                  value: emp['id'],
                  child: Text(emp['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedEmployee2 = value),
            ),
            const SizedBox(height: 16),
            
            // Start date selection
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('dd MMM yyyy').format(startDate)),
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 16),
            
            // Employee order selection
            SwitchListTile(
              title: Text('${selectedEmployee1 != null ? _getEmployeeName(selectedEmployee1!) : 'Employee 1'} starts first'),
              value: employee1StartsFirst,
              onChanged: (value) => setState(() => employee1StartsFirst = value),
            ),
            const SizedBox(height: 16),
            
            // Setup button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _setupRotation,
                icon: const Icon(Icons.save),
                label: const Text('Setup Rotation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build schedule preview card
  Widget _buildSchedulePreviewCard() {
    if (schedulePreview.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Schedule Preview (Next 14 Days)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...schedulePreview.entries.map((entry) {
              final date = DateTime.parse(entry.key);
              final schedule = entry.value;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(schedule['employeeName']),
                subtitle: Text(DateFormat('EEE, dd MMM yyyy').format(date)),
                trailing: const Text(
                  '4PM-6PM',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// Get employee name by ID
  String _getEmployeeName(String employeeId) {
    final employee = adminOfficeEmployees.firstWhere(
      (emp) => emp['id'] == employeeId,
      orElse: () => {'name': 'Unknown'},
    );
    return employee['name'];
  }
}
