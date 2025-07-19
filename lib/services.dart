import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> Addemployee({
  required String name,
  required String number,
  required String state,
  required String salary,
  required String section,
  required BuildContext context,
}) async {
  try {
    await FirebaseFirestore.instance.collection("Employees").add({
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
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
Stream<QuerySnapshot> getemployees(){
  return FirebaseFirestore.instance.collection("Employees").snapshots();
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
  required BuildContext context,
}) async {
  try {
    await FirebaseFirestore.instance.collection("Employees").doc(id).update({
      "name": name,
      "number": number,
      "state": state,
      "salary": salary,
      "section": section,
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