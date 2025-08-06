import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/kpi_models.dart';
import '../Services/services.dart';
import '../Services/section_shift_service.dart';

class AttendanceKPIDashboard extends StatefulWidget {
  const AttendanceKPIDashboard({Key? key}) : super(key: key);

  @override
  State<AttendanceKPIDashboard> createState() => _AttendanceKPIDashboardState();
}

class _AttendanceKPIDashboardState extends State<AttendanceKPIDashboard> {
  KPITimeFrame selectedTimeFrame = KPITimeFrame.monthly;
  DateTime selectedDate = DateTime.now();
  String? selectedSection;
  String? selectedEmployee;

  List<String> sections = [
    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
  ];

  List<SectionAttendanceSummary>? allSectionsSummary;
  SectionAttendanceSummary? sectionSummary;
  AttendanceKPI? employeeKPI;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadKPIData();
  }

  Future<void> _loadKPIData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // OPTIMIZATION: Preload employee data on first load
      if (selectedSection == null && selectedEmployee == null) {
        await preloadEmployeeData();
      }

      final (startDate, endDate) = _getDateRange();

      final filter = KPIFilter(
        timeFrame: selectedTimeFrame,
        startDate: startDate,
        endDate: endDate,
        department: selectedSection,
        employeeId: selectedEmployee,
      );

      final kpiData = await getAttendanceKPIData(filter);

      setState(() {
        if (kpiData['type'] == 'all_sections') {
          allSectionsSummary = (kpiData['data'] as List<dynamic>)
              .cast<SectionAttendanceSummary>();
          sectionSummary = null;
          employeeKPI = null;
        } else if (kpiData['type'] == 'section') {
          sectionSummary = kpiData['data'] as SectionAttendanceSummary;
          allSectionsSummary = null;
          employeeKPI = null;
        } else if (kpiData['type'] == 'employee') {
          employeeKPI = kpiData['data'] as AttendanceKPI;
          allSectionsSummary = null;
          sectionSummary = null;
        }
        isLoading = false;

        // Show cache status in debug mode
        if (kpiData.containsKey('cached') && kpiData['cached'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data loaded from cache'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = selectedDate;
    switch (selectedTimeFrame) {
      case KPITimeFrame.daily:
        return (now, now);
      case KPITimeFrame.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return (startOfWeek, endOfWeek);
      case KPITimeFrame.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return (startOfMonth, endOfMonth);
      case KPITimeFrame.quarterly:
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startOfQuarter = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        final endOfQuarter = DateTime(now.year, quarter * 3 + 1, 0);
        return (startOfQuarter, endOfQuarter);
      case KPITimeFrame.yearly:
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return (startOfYear, endOfYear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance KPI Dashboard'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              clearKPICache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  duration: Duration(seconds: 1),
                ),
              );
              await _loadKPIData();
            },
            tooltip: 'Clear Cache & Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKPIData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Simple Filters
          Card(
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
                          if (selected) {
                            setState(() {
                              selectedTimeFrame = timeFrame;
                            });
                            _loadKPIData();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Section Filter
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSection,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Sections'),
                      ),
                      ...sections.map((section) => DropdownMenuItem<String>(
                        value: section,
                        child: Text(section),
                      )),
                    ],
                    onChanged: (section) {
                      setState(() {
                        selectedSection = section;
                        selectedEmployee = null;
                      });
                      _loadKPIData();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: isLoading
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
                              'Error loading KPI data',
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
                              onPressed: _loadKPIData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildKPIContent(),
          ),
        ],
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

  Widget _buildKPIContent() {
    if (allSectionsSummary != null) {
      return _buildAllSectionsView();
    } else if (sectionSummary != null) {
      return _buildSectionView();
    } else if (employeeKPI != null) {
      return _buildEmployeeView();
    } else {
      return const Center(
        child: Text('No attendance data available'),
      );
    }
  }

  Widget _buildAllSectionsView() {
    final sections = allSectionsSummary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Sections Attendance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...sections.map((section) => _buildSectionCard(section)),
        ],
      ),
    );
  }

  Widget _buildSectionCard(SectionAttendanceSummary section) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSection = section.sectionName;
          });
          _loadKPIData();
        },
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
                      section.sectionName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    SectionShiftService.getShiftTimeDisplay(section.sectionShift),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressIndicator(
                      percentage: section.sectionAttendanceRate,
                      label: 'Attendance',
                      color: _getAttendanceColor(section.sectionAttendanceRate),
                    ),
                  ),
                  Expanded(
                    child: _buildProgressIndicator(
                      percentage: section.sectionPunctualityRate,
                      label: 'Punctuality',
                      color: _getPunctualityColor(section.sectionPunctualityRate),
                    ),
                  ),
                  Expanded(
                    child: _buildProgressIndicator(
                      percentage: section.sectionEarlyArrivalRate,
                      label: 'Early Arrivals',
                      color: _getEarlyArrivalColor(section.sectionEarlyArrivalRate),
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
                    '${section.presentEmployees}/${section.totalEmployees}',
                    Icons.people,
                  ),
                  _buildStatItem(
                    'Shift',
                    '${SectionShiftService.getShiftDurationHours(section.sectionShift).toStringAsFixed(1)}h',
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

  Widget _buildSectionView() {
    final section = sectionSummary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${section.sectionName} Section',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Shift: ${SectionShiftService.getShiftTimeDisplay(section.sectionShift)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionCard(section),

          const SizedBox(height: 24),

          const Text(
            'Employee Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ...section.employeeKPIs.map((empKPI) => _buildEmployeeListTile(empKPI)),
        ],
      ),
    );
  }

  Widget _buildEmployeeView() {
    final kpi = employeeKPI!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.employeeName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Section: ${kpi.section}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Shift: ${SectionShiftService.getShiftTimeDisplay(kpi.sectionShift)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          _buildEmployeeListTile(kpi),

          const SizedBox(height: 24),

          // Detailed metrics
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  percentage: kpi.attendanceRate,
                  label: 'Attendance Rate',
                  color: _getAttendanceColor(kpi.attendanceRate),
                ),
              ),
              Expanded(
                child: _buildProgressIndicator(
                  percentage: kpi.punctualityRate,
                  label: 'Punctuality Rate',
                  color: _getPunctualityColor(kpi.punctualityRate),
                ),
              ),
              Expanded(
                child: _buildProgressIndicator(
                  percentage: kpi.earlyArrivalRate,
                  label: 'Early Arrival Rate',
                  color: _getEarlyArrivalColor(kpi.earlyArrivalRate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Additional stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detailed Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow('Working Days', '${kpi.totalWorkingDays}'),
                  _buildStatRow('Present Days', '${kpi.presentDays}'),
                  _buildStatRow('Absent Days', '${kpi.absentDays}'),
                  _buildStatRow('Late Arrivals', '${kpi.lateArrivals}'),
                  _buildStatRow('On-time Arrivals', '${kpi.onTimeArrivals}'),
                  _buildStatRow('Early Arrivals', '${kpi.earlyArrivals}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeListTile(AttendanceKPI kpi) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
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
            Text('Early Arrivals: ${kpi.earlyArrivals} (${kpi.earlyArrivalRate.toStringAsFixed(1)}%)',
                 style: TextStyle(color: _getEarlyArrivalColor(kpi.earlyArrivalRate), fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${kpi.earlyArrivals}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _getEarlyArrivalColor(kpi.earlyArrivalRate),
              ),
            ),
            Text(
              'Early',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            selectedEmployee = kpi.employeeId;
          });
          _loadKPIData();
        },
      ),
    );
  }

  Widget _buildProgressIndicator({
    required double percentage,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
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
                    fontSize: 12,
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
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

  Color _getEarlyArrivalColor(double rate) {
    if (rate >= 50) return Colors.purple;
    if (rate >= 25) return Colors.indigo;
    if (rate >= 10) return Colors.teal;
    return Colors.grey;
  }
}
