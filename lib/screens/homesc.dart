import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_projectry_app/model/Employeedetails.dart';
import 'package:student_projectry_app/Services/services.dart';

import 'package:student_projectry_app/screens/detail.dart';

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
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(emp.profileImageUrl),
                        ),
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
                          ],
                        ),
                        title: Text(
                          emp.name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Contact - ${emp.number}",
                          
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
                  content: Column(
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
                      TextField(
                        controller: namecont,
                        decoration: InputDecoration(
                          hintText: "Name",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: numbercont,
                        decoration: InputDecoration(
                          hintText: "Phone number",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: statecont,
                        decoration: InputDecoration(
                          hintText: "State",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: salarycont,
                        decoration: InputDecoration(
                          hintText: "Salary",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
      
                      DropdownButtonFormField<String>(
                        value: selectedSection,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedSection = newValue;
                            sectioncont.text = newValue ?? '';
                          });
                        },
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
                                ] // exclude 'All' if this is used for form entry
                                .map(
                                  (section) => DropdownMenuItem<String>(
                                    value: section,
                                    child: Text(section),
                                  ),
                                )
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
      
                      TextField(
                        controller: locationcont,
                        decoration: InputDecoration(
                          hintText: "Home Address",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latitudecont,
                              decoration: InputDecoration(
                                hintText: "Latitude",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: longitudecont,
                              decoration: InputDecoration(
                                hintText: "Longitude",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      // ...existing code...
                      SizedBox(height: 5),
      
                      Text("Upload identity proof ↓ "),
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
                              salary: salarycont.text,
                              section: sectioncont.text,
                              context: context,
                              imageUrl: imageUrl ?? "",
                              profileimageUrl: profileimageUrl ?? "",
                              location: locationcont.text,
                              latitude: double.tryParse(latitudecont.text) ?? 0.0,
                              longitude:
                                  double.tryParse(longitudecont.text) ?? 0.0,
                            );
                          },
                          child: Text(
                            "Add Employee",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
