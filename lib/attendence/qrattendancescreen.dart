import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:student_projectry_app/Services/services.dart';

class QRAttendanceScreen extends StatefulWidget {
  const QRAttendanceScreen({super.key});

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen> {
  bool hasScanned = false;
  Map<String, dynamic>? scannedEmployee;

  final MobileScannerController _controller = MobileScannerController(); // ✅ single controller

  String get formattedDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> handleScan(String employeeId) async {
    if (hasScanned) return;

    setState(() => hasScanned = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Employees')
          .doc(employeeId)
          .get();

      if (!doc.exists) {
        _showMessage("Employee not found.");
        return;
      }

      final data = doc.data()!;
      setState(() {
        scannedEmployee = {
          'id': doc.id,
          'name': data['name'],
          'profileImageUrl': data['profileimage'],
        };
      });

      await markAttendanceByAdmin(
        employeeId: doc.id,
        name: data['name'],
        status: 'Present',
        date: formattedDate,
      );

      _showMessage("Attendance marked for ${data['name']}");

      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        hasScanned = false;
        scannedEmployee = null;
      });

    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Attendance Scanner"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final code = barcode.rawValue;
                if (code != null) {
                  handleScan(code);
                }
              }
              
              
                
              
            },
          ),
          if (scannedEmployee != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          NetworkImage(scannedEmployee!['profileImageUrl']),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      scannedEmployee!['name'],
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text("Attendance marked successfully!",
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
