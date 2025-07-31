import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrImageView, QrVersions;
import 'package:student_projectry_app/attendence/employeeattendancehistory.dart.dart';
import 'package:student_projectry_app/attendence/qrscreenwithdialogou.dart';

import 'package:student_projectry_app/model/Employeedetails.dart';
import 'package:student_projectry_app/Services/services.dart';


import 'package:student_projectry_app/screens/detail.dart';
import 'package:student_projectry_app/widgets/qrcodegen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();}
Widget buildTextField(String hint, TextEditingController controller, {bool number = false}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
    ),
    keyboardType: number ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    inputFormatters: number
        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
        : [],
  );
}

class _HomeState extends State<Home> {
  void showQrDialogWithSave({
  required BuildContext context,
  required String employeeId,
  required String employeeName,
}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(employeeName),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 300, // You can adjust width as needed
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: employeeId,
                version: QrVersions.auto,
                size: 200,
              ),
              SizedBox(height: 16),
              Text("Employee ID: $employeeId"),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text("Save as PDF"),
          onPressed: () async {
            Navigator.of(context).pop(); // Close dialog
            await saveQrCodeAsPdf(
              employeeId: employeeId,
              employeeName: employeeName,
            );
          },
        ),
        TextButton(
          child: Text("Close"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

  TextEditingController namecont = TextEditingController();
  TextEditingController numbercont = TextEditingController();
  TextEditingController statecont = TextEditingController();
  TextEditingController salarycont = TextEditingController();
  TextEditingController sectioncont = TextEditingController();
  TextEditingController locationcont = TextEditingController();
  TextEditingController latitudecont = TextEditingController();
  TextEditingController longitudecont = TextEditingController();
  TextEditingController joincont = TextEditingController();
  DateTime? selectedJoiningDate;
  TextEditingController districtcont = TextEditingController();

  String? selectedSection;
  int currentTabIndex = 0;

  void setSection(String? section) {
    setState(() {
      selectedSection = section;
      Navigator.pop(context);
    });
  }

  void editbox(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  namecont.text = data['name'];
  numbercont.text = data['number'];
  statecont.text = data['state'];
  salarycont.text = data['salary'];
  sectioncont.text = data['section'];
  locationcont.text = data['location'];
  latitudecont.text = data['latitude'].toString();
  longitudecont.text = data['longitude'].toString();
bool isActive = data.containsKey('status') ? data['status'] : true;
  String? selectedDropdownSection = data['section'];
  
    showDialog(
      context: context,
      builder: (context) {
        bool isActive = doc.data().toString().contains('status') ? doc['status'] : true;
        String? selectedDropdownSection = doc['section'];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Edit Employee"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildTextField("Name", namecont),
                    SizedBox(height: 5),
                    buildTextField("Phone number", numbercont),
                    SizedBox(height: 5),
                    buildTextField("State", statecont),
                    SizedBox(height: 5),
                    buildTextField("Salary", salarycont),
                    SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: selectedDropdownSection,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDropdownSection = newValue;
                          sectioncont.text = newValue ?? '';
                        });
                      },
                      items: [
                        'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
                        'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
                      ]
                          .map((section) => DropdownMenuItem<String>(
                                value: section,
                                child: Text(section),
                              ))
                          .toList(),
                      decoration: InputDecoration(
                        hintText: "Select Section",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    buildTextField("Home Address", locationcont),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(child: buildTextField("Latitude", latitudecont)),
                        SizedBox(width: 5),
                        Expanded(child: buildTextField("Longitude", longitudecont)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${isActive ? "Active" : "Inactive"}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            setState(() {
                              isActive = value;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        updateemployee(
                          id: doc.id,
                          name: namecont.text,
                          number: numbercont.text,
                          state: statecont.text,
                          salary: salarycont.text,
                          section: sectioncont.text,
                          location: locationcont.text,
                          latitude: double.tryParse(latitudecont.text) ?? 0.0,
                          longitude: double.tryParse(longitudecont.text) ?? 0.0,
                          isActive: isActive,
                          context: context,
                        );
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Update Employee",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Employees",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          bottom: TabBar(
            onTap: (index) {
              setState(() => currentTabIndex = index);
            },
            tabs: [
              Tab(text: "All",),
              Tab(text: "Active"),
              Tab(text: "Inactive"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButton<String>(
                value: selectedSection,
                hint: Text("Section", style: TextStyle(color: Colors.white)),
                dropdownColor: Colors.white,
                underline: SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                items: [
                  DropdownMenuItem(value: null, child: Text("All")),
                  ...[
                    'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
                    'Wire', 'Joint', 'V chain', 'Cutting', 'Box chain', 'Polish'
                  ].map((section) => DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      )),
                ],
                onChanged: (value) {
                  setState(() => selectedSection = value);
                },
              ),
            ),
          ],
        ),
        drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.lightBlue),
            child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Employees'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Mark Attendance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QRScanAttendanceScreendialogou(),
                ),
              );
            },
          ),
          ListTile(
        leading: Icon(Icons.history),
        title: Text('Attendance History'),
        onTap: () {
          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) =>EmployeeQRDailyLogHistoryScreen(),
  ),
);

        },
      ),
        ],
      ),
    ),
        body: Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: StreamBuilder(
            stream: getEmployees(section: selectedSection),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (!data.containsKey('status')) return currentTabIndex == 0;
                if (currentTabIndex == 1) return data['status'] == true;
                if (currentTabIndex == 2) return data['status'] == false;
                return true;
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  Employee emp = Employee.fromMap(
                    docs[index].data() as Map<String, dynamic>,
                  );

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeDetailPage(employee: emp),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                editbox(docs[index]);
                              },
                              icon: Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                deletemp(docs[index].id);
                              },
                              icon: Icon(Icons.delete),
                            ),
                            IconButton(onPressed: (){
                              showQrDialogWithSave(
                                context: context,
                                employeeId: docs[index].id,
                                employeeName: emp.name,
                              );
                            }, icon: Icon(Icons.qr_code))
                          ],
                        ),
                        title: Text(
                          emp.name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "section - ${emp.section}\n",
                          
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      

        floatingActionButton: FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        String? imageUrl;
        String? profileimageUrl;

        return AlertDialog(
          title: Text(
            "Add employee details",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 400, // optional fixed width
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    child: IconButton(
                      onPressed: () async {
                        final uploaded = await uploadToCloudinary();
                        if (uploaded != null) {
                          profileimageUrl = uploaded;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Image uploaded")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to upload image")),
                          );
                        }
                      },
                      icon: Icon(Icons.camera_alt),
                    ),
                  ),
                  SizedBox(height: 10),
                  buildTextField("Name", namecont),
                  SizedBox(height: 5,),
                  buildTextField("Phone number", numbercont),
                  SizedBox(height: 5),
                  buildTextField("State", statecont),
                  SizedBox(height: 5),
                  buildTextField("District", districtcont),
                  SizedBox(height: 5),
                  buildTextField("Salary", salarycont),
                  SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSection = newValue;
                        sectioncont.text = newValue ?? '';
                      });
                    },
                    items: [
                      'Admin office', 'Anchor', 'Fancy', 'KK', 'Soldering',
                      'Wire', 'Joint', 'V chain', 'Cutting',
                      'Box chain', 'Polish',
                    ].map((section) => DropdownMenuItem(
                      value: section,
                      child: Text(section),
                    )).toList(),
                    decoration: InputDecoration(
                      hintText: "Select Section",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: joincont,
                    decoration: InputDecoration(
                      hintText: 'Joining date',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedJoiningDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedJoiningDate = pickedDate;
                              joincont.text =
                                  pickedDate.toLocal().toString().split(' ')[0];
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  buildTextField("Home Address", locationcont),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(child: buildTextField("Latitude", latitudecont,  )),
                      SizedBox(width: 5),
                      Expanded(child: buildTextField("Longitude", longitudecont, )),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text("Upload identity proof ↓"),
                  CircleAvatar(
                    child: IconButton(
                      onPressed: () async {
                        final uploaded = await uploadToCloudinary();
                        if (uploaded != null) {
                          imageUrl = uploaded;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Image uploaded")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to upload image")),
                          );
                        }
                      },
                      icon: Icon(Icons.image),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () {
                        Addemployee(
                          name: namecont.text,
                          number: numbercont.text,
                          state: statecont.text,
                          district: districtcont.text,
                          salary: salarycont.text,
                          section: sectioncont.text,
                          joiningDate: joincont.text,
                          context: context,
                          imageUrl: imageUrl ?? "",
                          profileimageUrl: profileimageUrl ?? "",
                          location: locationcont.text,
                          latitude: double.tryParse(latitudecont.text) ?? 0.0,
                          longitude: double.tryParse(longitudecont.text) ?? 0.0,
                        );
                        // Clear fields
                        namecont.clear();
                        numbercont.clear();
                        statecont.clear();
                        salarycont.clear();
                        districtcont.clear();
                        locationcont.clear();
                        latitudecont.clear();
                        longitudecont.clear();
                        selectedSection = null;
                        joincont.clear();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        "Add Employee",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
  child: Icon(Icons.add),
  backgroundColor: Colors.blue,
  foregroundColor: Colors.white,
)


      ),
    );
  }
}
