import 'package:flutter/material.dart';
import 'package:student_projectry_app/imageview/imageview.dart';
import 'package:student_projectry_app/model/Employeedetails.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDetailPage extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailPage({Key? key, required this.employee})
    : super(key: key);
  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Divider(thickness: 1),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20),
          SizedBox(width: icon != null ? 8 : 0),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 22)),
          SizedBox(width: 6),
          Expanded(child: Text(value, style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(employee.name)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(employee.profileImageUrl),
            ),
            SizedBox(height: 15),
            _infoCard("Contact", [
              _infoRow("Contact", employee.number, icon: Icons.phone),
            ]),
            _infoCard("State", [
              _infoRow("State", employee.state, icon: Icons.location_on),
            ]),
            _infoCard("Section", [
              _infoRow("Section", employee.section, icon: Icons.badge),
            ]),
            _infoCard("Salary", [
              _infoRow("Salary", "₹${employee.salary}", icon: Icons.attach_money),
            ]),
            _infoCard("Address", [
              _infoRow("Address", employee.location, icon: Icons.home),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  final url =
                      'https://www.google.com/maps/search/?api=1&query=${employee.latitude},${employee.longitude}';
                  launchUrl(Uri.parse(url));
                },
                child: Row(
                  children: [
                    Icon(Icons.map, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "View on Map",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            // Bottom Image Card
            Card(
              margin: const EdgeInsets.only(top: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Imageviewesc(imageUrl: employee.imageUrl),
                    ),
                  );
                },
                child: Hero(
                  tag: employee.imageUrl,
                  child: Image.network(
                    employee.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}}
