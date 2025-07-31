

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:student_projectry_app/Services/services.dart';

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

  Future<void> handleScan(BuildContext context, String scannedId) async {
    try {
      final empData = await getEmployeeByIdforqr(scannedId);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Mark Attendance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(empData['profileImageUrl'] ?? ''),
              ),
              const SizedBox(height: 10),
              Text(empData['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      await markQRAttendance(scannedId, "In", empData);
                    },
                  ),
                  SizedBox(width: 10,),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Check Out"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      Navigator.pop(context);
                      await markQRAttendance(scannedId, "Out", empData);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> markQRAttendance(String employeeId, String type, Map<String, dynamic> empData) async {
    final now = DateTime.now();

    // Shift logic: Start from 4 PM today to 3:59 PM next day
    final shiftStart = DateTime(now.year, now.month, now.day, 16);
    final effectiveShiftDate = now.isBefore(shiftStart) ? now.subtract(Duration(days: 1)) : now;
    final shiftDateKey = DateFormat('yyyy-MM-dd').format(effectiveShiftDate);

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
        ])
      });
    } else {
      await recordRef.set({
        'name': empData['name'],
        'id': employeeId,
        'profileImageUrl': empData['profileImageUrl'],
        'logs': [
          {'type': type, 'time': timeNowFormatted}
        ]
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
