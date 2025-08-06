import 'package:flutter/material.dart';
import '../model/kpi_models.dart';
import '../Services/section_shift_service.dart';

class SectionShiftConfigScreen extends StatefulWidget {
  const SectionShiftConfigScreen({Key? key}) : super(key: key);

  @override
  State<SectionShiftConfigScreen> createState() => _SectionShiftConfigScreenState();
}

class _SectionShiftConfigScreenState extends State<SectionShiftConfigScreen> {
  Map<String, SectionShift> sectionShifts = {};
  bool isLoading = true;
  String? errorMessage;

  final List<String> sections = [
    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering', 
    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
  ];

  @override
  void initState() {
    super.initState();
    _loadSectionShifts();
  }

  Future<void> _loadSectionShifts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final shifts = await SectionShiftService.loadSectionShiftsFromFirestore();
      setState(() {
        sectionShifts = shifts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _editSectionShift(String sectionName) async {
    final currentShift = sectionShifts[sectionName] ?? SectionShift(
      sectionName: sectionName,
      startTime: '09:00',
      endTime: '17:00',
      isOvernightShift: false,
    );

    final result = await showDialog<SectionShift>(
      context: context,
      builder: (context) => _SectionShiftEditDialog(
        sectionShift: currentShift,
      ),
    );

    if (result != null) {
      try {
        await SectionShiftService.updateSectionShift(
          sectionName: result.sectionName,
          startTime: result.startTime,
          endTime: result.endTime,
          isOvernightShift: result.isOvernightShift,
        );

        setState(() {
          sectionShifts[sectionName] = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.sectionName} shift updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating shift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Section Shift Configuration'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSectionShifts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading shifts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSectionShifts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final sectionName = sections[index];
                    final shift = sectionShifts[sectionName];
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.access_time,
                          color: Colors.blue[600],
                        ),
                        title: Text(
                          sectionName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: shift != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    SectionShiftService.getShiftTimeDisplay(shift),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Duration: ${SectionShiftService.getShiftDurationHours(shift).toStringAsFixed(1)} hours',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Not configured',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                        trailing: const Icon(Icons.edit),
                        onTap: () => _editSectionShift(sectionName),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SectionShiftEditDialog extends StatefulWidget {
  final SectionShift sectionShift;

  const _SectionShiftEditDialog({
    Key? key,
    required this.sectionShift,
  }) : super(key: key);

  @override
  State<_SectionShiftEditDialog> createState() => _SectionShiftEditDialogState();
}

class _SectionShiftEditDialogState extends State<_SectionShiftEditDialog> {
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late bool isOvernightShift;

  @override
  void initState() {
    super.initState();
    startTimeController = TextEditingController(text: widget.sectionShift.startTime);
    endTimeController = TextEditingController(text: widget.sectionShift.endTime);
    isOvernightShift = widget.sectionShift.isOvernightShift;
  }

  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final currentTime = TimeOfDay.fromDateTime(
      DateTime.tryParse('2023-01-01 ${controller.text}:00') ?? DateTime.now(),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      controller.text = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure ${widget.sectionShift.sectionName} Shift'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startTimeController,
              decoration: const InputDecoration(
                labelText: 'Start Time',
                hintText: 'HH:MM (24-hour format)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () => _selectTime(startTimeController),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: endTimeController,
              decoration: const InputDecoration(
                labelText: 'End Time',
                hintText: 'HH:MM (24-hour format)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () => _selectTime(endTimeController),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Overnight Shift'),
              subtitle: const Text('Check if shift crosses midnight'),
              value: isOvernightShift,
              onChanged: (value) {
                setState(() {
                  isOvernightShift = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedShift = SectionShift(
              sectionName: widget.sectionShift.sectionName,
              startTime: startTimeController.text,
              endTime: endTimeController.text,
              isOvernightShift: isOvernightShift,
            );
            Navigator.of(context).pop(updatedShift);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
