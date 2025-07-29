import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class EmployeeQRCode extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeQRCode({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeQRCode> createState() => _EmployeeQRCodeState();
}

class _EmployeeQRCodeState extends State<EmployeeQRCode> {
  final GlobalKey globalKey = GlobalKey();

  Future<void> saveQrToGallery() async {
    try {
      // Ask permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission denied")),
        );
        return;
      }

      // Capture image
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to file
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/${widget.employeeName}_qr.png';
      File file = File(path);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR saved to: $path")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving QR: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("QR for ${widget.employeeName}"),
      content: RepaintBoundary(
        key: globalKey,
        child: SizedBox(
          width: 200,
          height: 200,
          child: QrImageView(
            data: widget.employeeId,
            version: QrVersions.auto,
            size: 200.0,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saveQrToGallery,
          child: const Text("Save QR"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
