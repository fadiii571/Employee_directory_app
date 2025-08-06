import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrImageView, QrVersions;

import 'package:student_projectry_app/attendence/employeeattendancehistory.dart.dart';
import 'package:student_projectry_app/attendence/qrscreenwithdialogou.dart';
import 'package:student_projectry_app/model/Employeedetails.dart';
import 'package:student_projectry_app/Services/services.dart';
import 'package:student_projectry_app/payroll/markpaidleave.dart';
import 'package:student_projectry_app/payroll/paidleavehistory.dart';
import 'package:student_projectry_app/screens/detail.dart';

import 'package:student_projectry_app/payroll/payrollscreen2.dart';
import 'package:student_projectry_app/screens/qrscreen.dart';
import 'package:student_projectry_app/screens/kpi_dashboard.dart';
import 'package:student_projectry_app/screens/section_shift_config.dart';
import 'package:student_projectry_app/widgets/qrcodegen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController namecont = TextEditingController();
  TextEditingController numbercont = TextEditingController();
  TextEditingController statecont = TextEditingController();
  TextEditingController salarycont = TextEditingController();
  TextEditingController sectioncont = TextEditingController();
  TextEditingController locationcont = TextEditingController();
  TextEditingController latitudecont = TextEditingController();
  TextEditingController longitudecont = TextEditingController();
  TextEditingController joincont = TextEditingController();
  TextEditingController districtcont = TextEditingController();
  DateTime? selectedJoiningDate;

  String? selectedSection;
  int currentTabIndex = 0;

  void setSection(String? section) {
    setState(() {
      selectedSection = section;
      Navigator.pop(context);
    });
  }

  Widget buildTextField(
    String hint,
    TextEditingController controller, {
    bool number = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType:
          number
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      inputFormatters:
          number
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [],
    );
  }

  void showQrDialogWithSave({
    required BuildContext context,
    required String employeeId,
    required String employeeName,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(employeeName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: employeeId,
                  version: QrVersions.auto,
                  size: 200,
                ),
                const SizedBox(height: 16),
                Text("Employee ID: $employeeId"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                saveQrCodeAsPdf(
                  employeeId: employeeId,
                  employeeName: employeeName,
                );
                Navigator.of(context).pop();
              },
              child: const Text("Save as PDF"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void editbox(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    namecont.text = data['name'] ?? '';
    numbercont.text = data['number'] ?? '';
    statecont.text = data['state'] ?? '';
    salarycont.text = data['salary'] ?? '';
    sectioncont.text = data['section'] ?? '';
    locationcont.text = data['location'] ?? '';
    latitudecont.text = (data['latitude'] ?? '').toString();
    longitudecont.text = (data['longitude'] ?? '').toString();
    bool isActive = data['active'] ?? true;
    bool notify = data['notify'] ?? false;
    showDialog(
      context: context,
      builder: (dialogcontext) {
      
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Edit Employee",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: namecont,
                        decoration: const InputDecoration(labelText: "Name"),
                      ),
                      TextField(
                        controller: numbercont,
                        decoration: const InputDecoration(labelText: "Number"),
                        keyboardType: TextInputType.phone,
                      ),
                      TextField(
                        controller: statecont,
                        decoration: const InputDecoration(labelText: "State"),
                      ),
                      TextField(
                        controller: salarycont,
                        decoration: const InputDecoration(labelText: "Salary"),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: sectioncont,
                        decoration: const InputDecoration(labelText: "Section"),
                      ),
                      TextField(
                        controller: locationcont,
                        decoration: const InputDecoration(
                          labelText: "Location",
                        ),
                      ),
                      TextField(
                        controller: latitudecont,
                        decoration: const InputDecoration(
                          labelText: "Latitude",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: longitudecont,
                        decoration: const InputDecoration(
                          labelText: "Longitude",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text("Active"),
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                      ),
                      SizedBox(height: 5,),
                      SwitchListTile(
  title: const Text("Send Notification on Check-In/Out"),
  value: notify,
  onChanged: (value) {
    setState(() {
      notify = value;
    });
  },
),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await updateemployee(
                            id: doc.id,
                            name: namecont.text,
                            number: numbercont.text,
                            state: statecont.text,
                            salary: salarycont.text,
                            section: sectioncont.text,
                            location: locationcont.text,
                            latitude: double.tryParse(latitudecont.text) ?? 0.0,
                            longitude:
                                double.tryParse(longitudecont.text) ?? 0.0,
                            isActive: isActive,
                            notify: notify,
                            context: context,
                          );
                         
                          Navigator.pop(dialogcontext);
                        },
                        child: const Text("Update"),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void showAddEmployeeDialog() {
    namecont.clear();
    numbercont.clear();
    statecont.clear();
    salarycont.clear();
    sectioncont.clear();
    locationcont.clear();
    latitudecont.clear();
    longitudecont.clear();
    String? profileimageUrl;
    String? imageUrl;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Add Employee Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 10),
                    CircleAvatar(
                      radius: 30,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: () async {
                          final uploaded = await uploadToFirebaseStorage();
                          if (uploaded != null) {
                            profileimageUrl = uploaded;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Profile uploaded")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Upload failed")),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    buildTextField("Name", namecont),
                    SizedBox(height: 10),
                    buildTextField("Phone Number", numbercont),
                    SizedBox(height: 10),
                    buildTextField("State", statecont),
                    SizedBox(height: 10),
                    buildTextField("District", districtcont),
                    SizedBox(height: 10),
                    buildTextField("Salary", salarycont),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: InputDecoration(
                        hintText: "Select Section",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items:
                          [
                                'Admin office',
                                'Anchor',
                                'Fancy',
                                'KK',
                                'Soldering',
                                'Wire',
                                'Joint',
                                'V chain',
                                'Cutting',
                                'Box chain',
                                'Polish',
                              ]
                              .map(
                                (section) => DropdownMenuItem(
                                  value: section,
                                  child: Text(section),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSection = val;
                          sectioncont.text = val ?? '';
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: joincont,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: "Joining Date",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  selectedJoiningDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedJoiningDate = picked;
                                joincont.text =
                                    picked.toIso8601String().split('T').first;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    buildTextField("Home Address", locationcont),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField(
                            "Latitude",
                            latitudecont,
                            number: true,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: buildTextField(
                            "Longitude",
                            longitudecont,
                            number: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text("Upload Identity Proof"),
                    CircleAvatar(
                      radius: 30,
                      child: IconButton(
                        icon: Icon(Icons.image),
                        onPressed: () async {
                          final uploaded = await uploadToFirebaseStorage();
                          if (uploaded != null) {
                            imageUrl = uploaded;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Document uploaded")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Upload failed")),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
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
                        minimumSize: Size(double.infinity, 45),
                      ),
                      child: Text(
                        "Add Employee",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          
          title: Text(
            "Employees",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 3,
          bottom: TabBar(
            onTap: (index) => setState(() => currentTabIndex = index),
            tabs: const [
              Tab(text: "All",),
              Tab(text: "Active"),
              Tab(text: "Inactive"),
            ],
          ),
          actions: [
            DropdownButton<String>(
              value: selectedSection,
              hint: Text("Section", style: TextStyle(color: Colors.white)),
              underline: SizedBox(),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Colors.black),
              items: [
                DropdownMenuItem(value: null, child: Text("All")),
                ...[
                  'Admin office',
                  'Anchor',
                  'Fancy',
                  'KK',
                  'Soldering',
                  'Wire',
                  'Joint',
                  'V chain',
                  'Cutting',
                  'Box chain',
                  'Polish',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (val) => setState(() => selectedSection = val),
            ),
            SizedBox(width: 12),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Employees"),
                onTap: () => Navigator.pop(context),
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.check_circle_outline),
                title: Text("Mark Attendance"),
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
                title: Text("Attendance History"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeQRDailyLogHistoryScreen(),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.analytics),
                title: Text("KPI Dashboard"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceKPIDashboard(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.schedule),
                title: Text("Section Shift Config"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SectionShiftConfigScreen(),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.payment),
                title: Text("Payroll"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GenerateAndViewPayrollScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.markunread_mailbox_sharp),
                title: Text('Mark Paid Leave'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarkPaidLeaveScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history_rounded),
                title: Text("Paid leave history"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>PaidLeaveHistoryScreen() ,));
                },
              ),
              Divider(),
            ],
          ),
        ),
        body: Container(
          padding: EdgeInsets.all(10),
          child: StreamBuilder(
            stream: getEmployees(section: selectedSection),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final docs =
                  snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (!data.containsKey('status'))
                      return currentTabIndex == 0;
                    return (currentTabIndex == 1 && data['status'] == true) ||
                        (currentTabIndex == 2 && data['status'] == false) ||
                        currentTabIndex == 0;
                  }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  Employee emp = Employee.fromMap(
                    docs[index].data() as Map<String, dynamic>,
                  );
                  return Card(
                    elevation: 4,
                   
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        emp.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Section: ${emp.section}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code),
                            tooltip: "View QR & Share",
                            onPressed: () {
                              final employee = Employee.fromMap(
                                docs[index].data() as Map<String, dynamic>,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EmployeeQrViewScreen(
                                        employeeId: docs[index].id,
                                        employeeName: employee.name,
                                      ),
                                ),
                              );
                            },
                          ),

                          IconButton(
                            onPressed: () => editbox(docs[index]),
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(
                           onPressed: () {
                             showDialog(context: context, builder: (context)=>AlertDialog(
                              title: Text('Delete employee'),
                              content: Text("Are you sure you want to delete this employee?"),
                              actions: [
                                TextButton(onPressed: () => 
                                   Navigator.of(context).pop(),
                                 child: Text("Cancel")),
                                 TextButton(onPressed: () {
                                   deletemp(docs[index].id);
              Navigator.of(context).pop();
                                 }, child: Text("Delete",style: TextStyle(color: Colors.red),))
                              ],
                             ));
                           },
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeeDetailPage(employee: emp),
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
          onPressed: showAddEmployeeDialog,
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
