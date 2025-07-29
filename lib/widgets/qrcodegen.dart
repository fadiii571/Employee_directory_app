import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EmployeeQRCode extends StatelessWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeQRCode({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("QR for $employeeName"),
      content: QrImageView(
        data: employeeId,
        version: QrVersions.auto,
        size: 200.0,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
