import 'package:flutter/material.dart';
import 'package:student_projectry_app/widgets/qrcodegen.dart';

class EmployeeQrViewScreen extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeQrViewScreen({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  Future<void> _generateAndSharePdf(BuildContext context) async {
    try {
      // Use the new enhanced QR code generator
      await saveQrCodeAsPdf(
        employeeId: employeeId,
        employeeName: employeeName,
        section: null, // You can add section info if available
        share: true,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR Code PDF generated and shared!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR for $employeeName")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use the new clean QR widget
              CleanQRCodeWidget(
                employeeId: employeeId,
                employeeName: employeeName,
                size: 250,
                showEmployeeInfo: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text("Share QR as PDF"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _generateAndSharePdf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
