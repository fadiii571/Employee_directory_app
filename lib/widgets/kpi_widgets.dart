import 'package:flutter/material.dart';
import '../model/kpi_models.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const KPICard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: backgroundColor ?? Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceProgressIndicator extends StatelessWidget {
  final double percentage;
  final String label;
  final Color color;
  final double size;

  const AttendanceProgressIndicator({
    Key? key,
    required this.percentage,
    required this.label,
    required this.color,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class EmployeeKPIListTile extends StatelessWidget {
  final AttendanceKPI kpi;
  final VoidCallback? onTap;

  const EmployeeKPIListTile({
    Key? key,
    required this.kpi,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getAttendanceColor(kpi.attendanceRate),
          child: Text(
            '${kpi.attendanceRate.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          kpi.employeeName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Present: ${kpi.presentDays}/${kpi.totalWorkingDays} days'),
            Text('Punctuality: ${kpi.punctualityRate.toStringAsFixed(1)}%'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${kpi.onTimeArrivals}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'On Time',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    return Colors.red;
  }
}

class SectionAttendanceCard extends StatelessWidget {
  final SectionAttendanceSummary sectionSummary;
  final VoidCallback? onTap;

  const SectionAttendanceCard({
    Key? key,
    required this.sectionSummary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.business,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sectionSummary.sectionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Shift: ${sectionSummary.sectionShift.startTime} - ${sectionSummary.sectionShift.endTime}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AttendanceProgressIndicator(
                      percentage: sectionSummary.sectionAttendanceRate,
                      label: 'Attendance',
                      color: _getAttendanceColor(sectionSummary.sectionAttendanceRate),
                      size: 60,
                    ),
                  ),
                  Expanded(
                    child: AttendanceProgressIndicator(
                      percentage: sectionSummary.sectionPunctualityRate,
                      label: 'Punctuality',
                      color: _getPunctualityColor(sectionSummary.sectionPunctualityRate),
                      size: 60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    'Employees',
                    '${sectionSummary.presentEmployees}/${sectionSummary.totalEmployees}',
                    Icons.people,
                  ),
                  _buildStatItem(
                    'Duration',
                    '${_getShiftDuration()}h',
                    Icons.access_time,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getShiftDuration() {
    try {
      final start = _parseTime(sectionSummary.sectionShift.startTime);
      final end = _parseTime(sectionSummary.sectionShift.endTime);

      if (sectionSummary.sectionShift.isOvernightShift) {
        final adjustedEnd = end.add(const Duration(days: 1));
        return adjustedEnd.difference(start).inMinutes / 60.0;
      } else {
        return end.difference(start).inMinutes / 60.0;
      }
    } catch (e) {
      return 8.0;
    }
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    return Colors.red;
  }

  Color _getPunctualityColor(double score) {
    if (score >= 85) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }
}

class KPIFilterWidget extends StatelessWidget {
  final KPITimeFrame selectedTimeFrame;
  final DateTime selectedDate;
  final String? selectedDepartment;
  final String? selectedEmployee;
  final List<String> departments;
  final List<Map<String, String>> employees;
  final Function(KPITimeFrame) onTimeFrameChanged;
  final Function(DateTime) onDateChanged;
  final Function(String?) onDepartmentChanged;
  final Function(String?) onEmployeeChanged;

  const KPIFilterWidget({
    Key? key,
    required this.selectedTimeFrame,
    required this.selectedDate,
    this.selectedDepartment,
    this.selectedEmployee,
    required this.departments,
    required this.employees,
    required this.onTimeFrameChanged,
    required this.onDateChanged,
    required this.onDepartmentChanged,
    required this.onEmployeeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Time Frame Selection
            Wrap(
              spacing: 8,
              children: KPITimeFrame.values.map((timeFrame) {
                return ChoiceChip(
                  label: Text(_getTimeFrameLabel(timeFrame)),
                  selected: selectedTimeFrame == timeFrame,
                  onSelected: (selected) {
                    if (selected) onTimeFrameChanged(timeFrame);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Department Filter
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              value: selectedDepartment,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Departments'),
                ),
                ...departments.map((dept) => DropdownMenuItem<String>(
                  value: dept,
                  child: Text(dept),
                )),
              ],
              onChanged: onDepartmentChanged,
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeFrameLabel(KPITimeFrame timeFrame) {
    switch (timeFrame) {
      case KPITimeFrame.daily:
        return 'Daily';
      case KPITimeFrame.weekly:
        return 'Weekly';
      case KPITimeFrame.monthly:
        return 'Monthly';
      case KPITimeFrame.quarterly:
        return 'Quarterly';
      case KPITimeFrame.yearly:
        return 'Yearly';
    }
  }
}
