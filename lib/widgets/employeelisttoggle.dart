import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef EditCallback = void Function(DocumentSnapshot doc);

class EmployeeList extends StatelessWidget {
  final bool? status;
  final EditCallback onEdit;

  const EmployeeList({
    Key? key,
    this.status,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('employees');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No employees found."));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text(doc['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone: ${doc['number']}"),
                    Text("Status: ${doc['status'] ? 'Active' : 'Inactive'}"),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => onEdit(doc),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
