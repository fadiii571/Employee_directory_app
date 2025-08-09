

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/services.dart';
import 'package:student_projectry_app/widgets/qrcodegen.dart';

class QRScanAttendanceScreendialogou extends StatefulWidget {
  const QRScanAttendanceScreendialogou({super.key});

  @override
  State<QRScanAttendanceScreendialogou> createState() => _QRScanAttendanceScreenState();
}

class _QRScanAttendanceScreenState extends State<QRScanAttendanceScreendialogou> {
  final MobileScannerController _controller = MobileScannerController();
  bool isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> handleScan(BuildContext context, String scannedData) async {
    try {
      // Validate QR code format
      if (!QRCodeGenerator.isValidEmployeeQR(scannedData)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid QR code format")),
          );
        }
        return;
      }

      // Extract employee ID from QR data
      final employeeId = QRCodeGenerator.extractEmployeeId(scannedData);

      // Debug logging
      debugPrint('Scanned QR Data: $scannedData');
      debugPrint('Extracted Employee ID: $employeeId');

      final empData = await getEmployeeByIdforqr(employeeId);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Mark Attendance"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: empData['profileImageUrl'] != null && empData['profileImageUrl'].isNotEmpty
                      ? NetworkImage(empData['profileImageUrl'])
                      : null,
                  child: empData['profileImageUrl'] == null || empData['profileImageUrl'].isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(empData['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('ID: $employeeId', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (empData['section'] != null)
                  Text('Section: ${empData['section']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text("Check In"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        Navigator.pop(context);
                        await markQRAttendance(employeeId, "Check In", empData);
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text("Check Out"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(context);
                        await markQRAttendance(employeeId, "Check Out", empData);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in handleScan: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  /// Calculate shift date using 4PM-4PM logic with extended checkout for special sections
  /// Admin Office, KK, and Fancy can checkout until 6PM next day but stored under shift start date
  DateTime _calculateShiftDate(DateTime now, String section) {
    final sectionLower = section.toLowerCase();

    // Special handling for Admin Office, KK, and Fancy (extended checkout until 6PM next day)
    if (sectionLower == 'admin office' || sectionLower == 'kk' || sectionLower == 'fancy') {
      if (now.hour < 16) {
        // Before 4PM = extended checkout from previous day's shift
        return DateTime(now.year, now.month, now.day - 1, 16);
      } else if (now.hour < 18) {
        // 4PM to 6PM = could be start of current shift OR extended checkout from previous shift
        // We need to determine based on whether it's the same day as shift start or next day

        // If it's the same day as when the shift started (4PM), it's current day's shift
        // If it's the next day, it's extended checkout from previous day's shift
        final currentShiftStart = DateTime(now.year, now.month, now.day, 16);
        final previousShiftStart = DateTime(now.year, now.month, now.day - 1, 16);

        // Check if we're within 26 hours of the previous shift start (4PM yesterday to 6PM today)
        final hoursSincePreviousShift = now.difference(previousShiftStart).inHours;

        if (hoursSincePreviousShift <= 26) {
          // Within extended checkout period - belongs to previous day's shift
          return previousShiftStart;
        } else {
          // New shift starting today
          return currentShiftStart;
        }
      } else {
        // 6PM or after = current day's shift (new shift starts)
        return DateTime(now.year, now.month, now.day, 16);
      }
    }

    // Standard 4PM-4PM logic for all other sections
    if (now.hour < 16) {
      // Before 4PM = previous day's shift
      return DateTime(now.year, now.month, now.day - 1, 16);
    } else {
      // 4PM or after = current day's shift
      return DateTime(now.year, now.month, now.day, 16);
    }
  }

  Future<void> markQRAttendance(String employeeId, String type, Map<String, dynamic> empData) async {
    final now = DateTime.now();
    final section = empData['section'] ?? '';

    // Use the same shift calculation logic as the main services
    final shiftDate = _calculateShiftDate(now, section);
    final shiftDateKey = DateFormat('yyyy-MM-dd').format(shiftDate);

    final timeNowFormatted = DateFormat('hh:mm a').format(now);

    final recordRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(shiftDateKey)
        .collection('records')
        .doc(employeeId);

    final snapshot = await recordRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
      final alreadyMarked = logs.any((log) => log['type'] == type);

      if (alreadyMarked) {
        showErrorDialog("Already marked $type for current shift.");
        return;
      }

      await recordRef.update({
        'logs': FieldValue.arrayUnion([
          {'type': type, 'time': timeNowFormatted}
        ]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      await recordRef.set({
        'employeeId': employeeId,
        'employeeName': empData['name'],
        'name': empData['name'], // Keep both for compatibility
        'section': section,
        'profileImageUrl': empData['profileImageUrl'] ?? '',
        'shiftDate': shiftDateKey,
        'logs': [
          {'type': type, 'time': timeNowFormatted}
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    showSuccessDialog("Marked $type at $timeNowFormatted");
  }

  void showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanned = false);
            },
          )
        ],
      ),
    );
  }

  void showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanned = false);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Attendance"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text("Scan Employee QR Code Below", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) async {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final code = barcode.rawValue;
                  if (code != null && !isScanned) {
                    setState(() => isScanned = true);
                    await handleScan(context, code);
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() => isScanned = false);
                    break;
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
