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


 
 Future<Map<String, List<Map<String, dynamic>>>> fetchAttendanceHistory({
  required DateTime selectedDate,
  required String viewType,
  required String selectedEmployeeId,
  required Map<String, String> employeeNames,
}) async {
  final firestore = FirebaseFirestore.instance;
  final Map<String, List<Map<String, dynamic>>> history = {};

  DateTime startDate = selectedDate;
  DateTime endDate = selectedDate;

  if (viewType == 'Weekly') {
    final weekDay = selectedDate.weekday;
    startDate = selectedDate.subtract(Duration(days: weekDay - 1));
    endDate = startDate.add(const Duration(days: 6));
  } else if (viewType == 'Monthly') {
    startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  }

  final dateList = List.generate(
    endDate.difference(startDate).inDays + 1,
    (i) => DateFormat('yyyy-MM-dd').format(startDate.add(Duration(days: i))),
  );

  for (final date in dateList) {
    final docRef = firestore.collection('attendance').doc(date).collection('records');
    final snapshot = await docRef.get();

    if (snapshot.docs.isEmpty) continue;

    List<Map<String, dynamic>> dayRecords = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      if (selectedEmployeeId.isNotEmpty && selectedEmployeeId != doc.id) {
        continue;
      }

      final logs = List<Map<String, dynamic>>.from(data['logs'] ?? []);
      final name = data['name'] ?? employeeNames[doc.id] ?? 'Unknown';
      final profileImageUrl = data['profileImageUrl'] ?? '';

      dayRecords.add({
        'name': name,
        'profileImageUrl': profileImageUrl,
        'logs': logs,
      });

      // Optional: Save employee name in map for dropdown usage
      if (!employeeNames.containsKey(doc.id)) {
        employeeNames[doc.id] = name;
      }
    }

    if (dayRecords.isNotEmpty) {
      history[date] = dayRecords;
    }
  }

  return history;
}

Future<void> generatePayrollForMonth(String monthYear) async {
  final _firestore = FirebaseFirestore.instance;

  final employeeSnapshot = await _firestore.collection('Employees').get();
  final year = int.parse(monthYear.split('-')[0]);
  final month = int.parse(monthYear.split('-')[1]);
  final totalDaysInMonth = DateUtils.getDaysInMonth(year, month);

  for (final employeeDoc in employeeSnapshot.docs) {
    final emp = employeeDoc.data();
    final empId = employeeDoc.id;

    final salary = double.tryParse(emp['salary'].toString()) ?? 0.0;

    int presentDays = 0;
    int paidLeaves = 0;
    int workingDays = 0;

    for (int day = 1; day <= totalDaysInMonth; day++) {
  final date = DateTime(year, month, day);
  final shiftStart = DateTime(date.year, date.month, date.day, 16); // 4 PM
  final shiftEnd = shiftStart.add(const Duration(hours: 24)); // Next day 4 PM

  // 🛑 Skip if the shift starts on Sunday (before Monday 4 PM)
  if (shiftStart.weekday == DateTime.sunday) continue;

  // 🛑 Skip if the shift ends on Monday before 4 PM (holiday period)
  final isHoliday = shiftEnd.weekday == DateTime.monday && shiftEnd.hour < 16;
  if (isHoliday) continue;

  workingDays++;

  final formatted = DateFormat('yyyy-MM-dd').format(shiftStart);

  final attendanceDoc = await _firestore
      .collection('attendance')
      .doc(formatted)
      .collection('records')
      .doc(empId)
      .get();

  final paidLeaveDoc = await _firestore
      .collection('paid_leaves')
      .doc(formatted)
      .collection('Employees')
      .doc(empId)
      .get();

  if (attendanceDoc.exists) {
    final logs = List.from(attendanceDoc.data()?['logs'] ?? []);
    final inLog = logs.any((log) => log['type'] == 'In');
    final outLog = logs.any((log) => log['type'] == 'Out');

    if (inLog && outLog) {
      presentDays++;
      continue;
    }
  }

  if (paidLeaveDoc.exists) {
    paidLeaves++;
  }
}

    final absentDays = workingDays - presentDays - paidLeaves;
    final dailyRate = salary / workingDays;
    final deduction = dailyRate * absentDays;
    final finalSalary = salary - deduction;

    await _firestore
        .collection('payroll')
        .doc(monthYear)
        .collection('Employees')
        .doc(empId)
        .set({
      'employeeId': empId,
      'name': emp['name'] ?? '',
      'baseSalary': salary,
      'presentDays': presentDays,
      'paidLeaves': paidLeaves,
      'absentDays': absentDays,
      'workingDays': workingDays,
      'deduction': deduction,
      'finalSalary': finalSalary,
      'status': 'Unpaid',
      'generatedAt': FieldValue.serverTimestamp(),
    });

    print(
        '✅ Generated payroll for ${emp['name']} — Final Salary: ₹${finalSalary.toStringAsFixed(2)}');
  }
}

Future<void> markPaidLeave(String employeeId, DateTime date, String reason) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final formatted = DateFormat('yyyy-MM-dd').format(date);

  await firestore
      .collection('paid_leaves')
      .doc(formatted)
      .collection('Employees')
      .doc(employeeId)
      .set({
    'reason': reason,
    'markedAt': FieldValue.serverTimestamp(),
  });
}
