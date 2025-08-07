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
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, size: 22),
          if (icon != null) const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print image URLs to console
    print('Profile Image URL: "${employee.profileImageUrl}"');
    print('Main Image URL: "${employee.imageUrl}"');

    return Scaffold(
      appBar: AppBar(title: Text(employee.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
          Hero(
  tag: 'profile_${employee.profileImageUrl}',
  child: CircleAvatar(
    radius: 50,
    backgroundColor: Colors.grey[300],
    backgroundImage: (employee.profileImageUrl.isNotEmpty)
        ? NetworkImage(employee.profileImageUrl)
        : null,
    child: (employee.profileImageUrl.isEmpty)
        ? const Icon(Icons.person, size: 40, color: Colors.grey)
        : null,
    onBackgroundImageError: (exception, stackTrace) {
      // Handle image loading error
      print('Error loading profile image: $exception');
    },
  ),
),


              const SizedBox(height: 20),

              _infoCard("Contact", [
                _infoRow("Phone", employee.number, icon: Icons.phone),
              ]),

              _infoCard("State", [
                _infoRow("State", employee.state, icon: Icons.location_on),
              ]),

              _infoCard("District", [
                _infoRow(
                  "District",
                  employee.district,
                  icon: Icons.location_city,
                ),
              ]),

              _infoCard("Section", [
                _infoRow("Section", employee.section, icon: Icons.badge),
              ]),

              _infoCard("Joining Date", [
                _infoRow("Date", employee.joiningDate, icon: Icons.date_range),
              ]),
              
              _infoCard("Salary", [
                _infoRow(
                  "Salary",
                  "₹${employee.salary}",
                  icon: Icons.attach_money,
                ),
              ]),

              _infoCard("Address", [
                _infoRow("Address", employee.location, icon: Icons.home),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final url =
                        'https://www.google.com/maps/search/?api=1&query=${employee.latitude},${employee.longitude}';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    }
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.map, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        "View on Map",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 16),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
