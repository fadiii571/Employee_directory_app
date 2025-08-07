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

  // Include Fancy and KK as configurable (they keep extended checkout but configurable check-in)
  final List<String> sections = [
    'Fancy', 'KK', 'Anchor', 'Soldering', 'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
  ];

  // Only Admin office has fully hardcoded logic (not configurable)
  final List<String> hardcodedSections = ['Admin office'];

  // Sections with extended checkout until 6PM (but configurable check-in)
  final List<String> extendedCheckoutSections = ['Fancy', 'KK'];

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
      // Initialize the service and get all shifts
      await SectionShiftService.initialize();
      final shifts = await SectionShiftService.getAllSectionShifts();
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
      checkInTime: '09:00',
      gracePeriodMinutes: 0,
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
          checkInTime: result.checkInTime,
          gracePeriodMinutes: result.gracePeriodMinutes,
        );

        setState(() {
          sectionShifts[sectionName] = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.sectionName} shift updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating shift: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          IconButton(
            onPressed: () async {
              // Debug Joint section configuration
              await SectionShiftService.debugJointSectionConfig();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check console for Joint section debug info')),
                );
              }
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Joint Section',
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
              : Column(
                  children: [
                    // Hardcoded sections info
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Hardcoded Shift Sections',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This section has fully hardcoded logic in markQRAttendance:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ...hardcodedSections.map((section) {
                            String shiftInfo;
                            if (section.toLowerCase() == 'fancy' || section.toLowerCase() == 'kk') {
                              shiftInfo = '$section - 5:30 AM check-in (10min grace), 4PM-4PM shift storage (extended checkout until 6PM)';
                            } else {
                              shiftInfo = '$section - 4PM shift start (extended checkout until 6PM next day)';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      shiftInfo,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const Text(
                            'KPI calculations: Admin Office uses 4PM check-in time.',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    // Extended checkout sections info
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Extended Checkout Sections',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'These sections have configurable check-in time but extended checkout until 6PM:',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ...extendedCheckoutSections.map((section) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$section - Configurable check-in time, extended checkout until 6PM',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 8),
                          const Text(
                            'Note: Check-in time is configurable, but checkout logic remains hardcoded in markQRAttendance.',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    // Configurable sections header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'All Configurable Sections',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Configurable sections list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    'Grace Period: ${shift.gracePeriodMinutes} minutes',
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
                    ),
                  ],
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
  late TextEditingController checkInTimeController;
  late int gracePeriodMinutes;

  @override
  void initState() {
    super.initState();
    checkInTimeController = TextEditingController(text: widget.sectionShift.checkInTime);
    gracePeriodMinutes = widget.sectionShift.gracePeriodMinutes;
  }

  @override
  void dispose() {
    checkInTimeController.dispose();
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
            const Text(
              'Configure Check-In Time for KPI Calculations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only check-in time is used for punctuality calculations. Check-out time is flexible.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: checkInTimeController,
              decoration: const InputDecoration(
                labelText: 'Check-In Time',
                hintText: 'HH:MM (24-hour format)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
                helperText: 'Expected arrival time for employees',
              ),
              readOnly: true,
              onTap: () => _selectTime(checkInTimeController),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Grace Period: '),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: gracePeriodMinutes,
                  items: [0, 5, 10, 15, 30].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minutes'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      gracePeriodMinutes = value ?? 0;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Grace period allows employees to arrive slightly late without being marked as late.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              checkInTime: checkInTimeController.text,
              gracePeriodMinutes: gracePeriodMinutes,
            );
            Navigator.of(context).pop(updatedShift);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
