import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

Future<void> Addemployee({
  required String name,
  required String number,
  required String state,
  required String district,
  required String salary,
  required String section,
  required String joiningDate,
  required String profileimageUrl,
  required String imageUrl,
  required String location,
  required double latitude,
  required double longitude,
  required BuildContext context,
}) async {
  try { 


    await FirebaseFirestore.instance.collection("Employees").add({
      "name": name,
      "number": number,
      "state": state,
      "district": district,
      "salary": salary,
      "section": section,
      "joiningDate": joiningDate,
      "image": imageUrl,
      "profileimage": profileimageUrl,
      "location": location,
      "latitude": latitude, 
      "longitude": longitude,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Employee added successfully",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
Future<String?> uploadToCloudinary() async {
  final cloudName = 'dzfr5nkxt';
  final uploadPreset = 'employee_images';
  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  Uint8List? imageBytes;
  String fileName;

  if (kIsWeb) {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.image);
    if (result == null || result.files.single.bytes == null) return null;
    imageBytes = result.files.single.bytes!;
    fileName = result.files.single.name;
  } else {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    imageBytes = await pickedFile.readAsBytes();
    fileName = pickedFile.name;
  }

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final data = json.decode(responseBody);
    return data['secure_url'];
  } else {
    print("Upload failed: ${response.reasonPhrase}");
    return null;
  }
}

 Stream<QuerySnapshot> getEmployees({String? section}) {
    if (section == null) {
      return FirebaseFirestore.instance.collection("Employees").snapshots();
    } else {
      return FirebaseFirestore.instance.collection("Employees").where("section", isEqualTo: section).snapshots();
    }
  }
Future<void> deletemp(String id)async{
  await FirebaseFirestore.instance.collection("Employees").doc(id).delete();
}
Future<void> updateemployee({
 required String id,
  required String name,
  required String number,
  required String state,
  required String salary,
  required String section,
  required String location,
  required double latitude,
  required double longitude,
  required bool isActive,
  required BuildContext context,
}) async {
  try {
    await FirebaseFirestore.instance.collection("Employees").doc(id).update({
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
      "location": location,
      "latitude": latitude, 
      "longitude": longitude,
      'status': isActive,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Employee data updated successfully",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}


Future<void> markQRAttendance(String employeeId, String type) async {
  final now = DateTime.now();
  final date = DateFormat('yyyy-MM-dd').format(now);
  final time = DateFormat('hh:mm a').format(now);

  final empDoc = await FirebaseFirestore.instance
      .collection('Employees')
      .doc(employeeId)
      .get();

  if (!empDoc.exists) {
    throw Exception("Employee not found");
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

    final alreadyMarked = logs.any((log) => log['type'] == type);
    if (alreadyMarked) {
      throw Exception("Already marked $type today.");
    }

    await recordRef.update({
      'logs': FieldValue.arrayUnion([
        {'time': time, 'type': type}
      ])
    });
  } else {
    await recordRef.set({
      'name': empData['name'],
      'id': employeeId,
      'profileImageUrl': empData['profileImageUrl'],
      'logs': [
        {'time': time, 'type': type}
      ]
    });
  }
}
Future<Map<String, dynamic>> getEmployeeByIdforqr(String id) async {
  final doc = await FirebaseFirestore.instance.collection('Employees').doc(id).get();
  if (!doc.exists) throw Exception("Employee not found");
  return doc.data()!;
}


Future<List<Map<String, dynamic>>> getQRDailyAttendance({
  required String date,
}) async {
  final attendanceRef = FirebaseFirestore.instance
      .collection('attendance')
      .doc(date)
      .collection('records');

  final snapshot = await attendanceRef.get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    data['id'] = doc.id;
    data['date'] = date;
    return data;
  }).toList();
}

class FirebaseService {
 
  Future<Map<String, List<Map<String, dynamic>>>> fetchAttendanceHistory({
    required DateTime selectedDate,
    required String viewType,
    required String selectedEmployeeId,
    required Map<String, String> employeeNames,
  }) async {
    List<String> datesToFetch = [];

    if (viewType == 'Daily') {
      datesToFetch = [DateFormat('yyyy-MM-dd').format(selectedDate)];
    } else if (viewType == 'Weekly') {
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      for (int i = 0; i < 7; i++) {
        datesToFetch.add(DateFormat('yyyy-MM-dd').format(startOfWeek.add(Duration(days: i))));
      }
    } else if (viewType == 'Monthly') {
      final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
      final endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      for (int i = 0; i < endOfMonth.day; i++) {
        datesToFetch.add(DateFormat('yyyy-MM-dd').format(startOfMonth.add(Duration(days: i))));
      }
    }

    Map<String, List<Map<String, dynamic>>> history = {};
    employeeNames.clear();

    for (String date in datesToFetch) {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(date)
          .collection('records')
          .get();

      for (var doc in snapshot.docs) {
        if (selectedEmployeeId.isEmpty || doc.id == selectedEmployeeId) {
          final data = doc.data();
          final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
          final name = data['name'] ?? '';
          employeeNames[doc.id] = name;

          history[date] ??= [];
          history[date]!.add({
            'id': doc.id,
            'name': name,
            'profileImageUrl': data['profileImageUrl'] ?? '',
            'logs': logs,
          });
        }
      }
    }

    return history;
  }
}

