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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              Imageviewesc(imageUrl: employee.imageUrl),
                    ),
                  );
                },
                child: Hero(
                  tag: employee.imageUrl,

                  child: Image.network(
                    employee.imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 5,),
              _infoCard("Employee Info", [
                _infoRow("Contact", employee.number, icon: Icons.phone),
                _infoRow("State", employee.state, icon: Icons.location_on),
                _infoRow("Section", employee.section, icon: Icons.badge),
                _infoRow(
                  "Salary",
                  "₹${employee.salary}",
                  icon: Icons.attach_money,
                ),
                _infoRow("Address", employee.location, icon: Icons.home),
               
                
                GestureDetector(
                  onTap: () {
                    final url = 'https://www.google.com/maps/search/?api=1&query=${employee.latitude},${employee.longitude}';
        launchUrl(Uri.parse(url));
                  },
                  child: Text("View on Map",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontSize: 18,
                    )),
                )
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
