/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class QRScanAttendanceScreen extends StatefulWidget {
  const QRScanAttendanceScreen({super.key});

  @override
  State<QRScanAttendanceScreen> createState() => _QRScanAttendanceScreenState();
}

class _QRScanAttendanceScreenState extends State<QRScanAttendanceScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool isScanned = false;
  String selectedType = 'In'; 

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showResult(String message, {bool success = true}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(success ? 'Success' : 'Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => isScanned = false); 
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> handleScan(String employeeId) async {
  if (isScanned) return;
  setState(() => isScanned = true);

  final now = DateTime.now();
  final date = DateFormat('yyyy-MM-dd').format(now);
  final time = DateFormat('hh:mm a').format(now);

  try {
    final empDoc = await FirebaseFirestore.instance
        .collection('Employees')
        .doc(employeeId)
        .get();

    if (!empDoc.exists) {
      showResult("Invalid QR - Employee not found", success: false);
      return;
    }

    final empData = empDoc.data()!;
    final recordRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(date)
        .collection('records')
        .doc(employeeId);

    final snapshot = await recordRef.get();

    if (snapshot.exists) {
      final existingData = snapshot.data()!;
      final List<dynamic> logs = existingData['logs'] ?? [];

      final alreadyMarked = logs.any((log) => log['type'] == selectedType);
      if (alreadyMarked) {
        throw Exception("Already marked $selectedType today.");
      }

      await recordRef.update({
        'logs': FieldValue.arrayUnion([
          {'time': time, 'type': selectedType}
        ])
      });
    } else {
      await recordRef.set({
        'name': empData['name'],
        'id': employeeId,
        'profileImageUrl': empData['profileImageUrl'],
        'logs': [
          {'time': time, 'type': selectedType}
        ]
      });
    }

    showResult("Marked $selectedType for ${empData['name']} at $time", success: true);
  } catch (e) {
    showResult("Error: $e", success: false);
  }
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
          const SizedBox(height: 10),
          Text(
            "Select Attendance Type",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['In', 'Out'].map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ChoiceChip(
                  label: Text(type),
                  selected: selectedType == type,
                  onSelected: (_) {
                    setState(() {
                      selectedType = type;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const Text("Scan Employee QR Code Below"),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  
                  onDetect: (BarcodeCapture capture) {
                    final List<Barcode> Barcodes=capture.barcodes;
                    for(final barcode in Barcodes){
                      final String? code = barcode.rawValue;
                      if(code != null && !isScanned) {
                        handleScan(code);
                        break;
                      }
                    }
                    
                     {
                      
                    
                  }
  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/
