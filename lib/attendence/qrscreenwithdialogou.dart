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
        title: Text("Mark Attendance"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(empData['profileImageUrl'] ?? ''),
            ),
            SizedBox(height: 10),
            Text(empData['name'], style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text("Check In"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await markQRAttendance(scannedId, "In");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checked In")));
                  },style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text("Check Out"),
                  onPressed: () async {
                    Navigator.pop(context);
                    await markQRAttendance(scannedId, "Out");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checked Out")));
                  },style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            )
          ],
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}


  Future<void> markAttendance(String employeeId, String type) async {
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('hh:mm a').format(now);

    final recordRef = FirebaseFirestore.instance
        .collection('attendance')
        .doc(date)
        .collection('records')
        .doc(employeeId);

    final snapshot = await recordRef.get();

    if (snapshot.exists) {
      final existingData = snapshot.data()!;
      final List<dynamic> logs = existingData['logs'] ?? [];

      final alreadyMarked = logs.any((log) => log['type'] == type);
      if (alreadyMarked) {
        showErrorDialog("Already marked $type today.");
        return;
      }

      await recordRef.update({
        'logs': FieldValue.arrayUnion([
          {'time': time, 'type': type}
        ])
      });
    } else {
      final empDoc = await FirebaseFirestore.instance
          .collection('Employees')
          .doc(employeeId)
          .get();

      final empData = empDoc.data()!;
      await recordRef.set({
        'name': empData['name'],
        'id': employeeId,
        'profileImageUrl': empData['profileImageUrl'],
        'logs': [
          {'time': time, 'type': type}
        ]
      });
    }

    Navigator.of(context).pop(); // Close dialog
    showSuccessDialog("Marked $type successfully at $time");
  }

  void showAttendanceDialog(String employeeId, String name, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(imageUrl)),
            const SizedBox(height: 20),
            const Text("Select Attendance Type"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Check In"),
                  onPressed: () => markAttendance(employeeId, 'In'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Check Out"),
                  onPressed: () => markAttendance(employeeId, 'Out'),
                ),
              ],
            )
          ],
        ),
      ),
    ).then((_) => setState(() => isScanned = false));
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => isScanned = false);
              },
              child: const Text("OK"))
        ],
      ),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"))
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
              onDetect: (capture) async{
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null && !isScanned) {
                    isScanned = true;
                    await handleScan(context,code);
                    await Future.delayed(Duration(seconds: 2));
                    isScanned = false; 
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
