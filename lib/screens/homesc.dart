import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_projectry_app/screens/detail.dart';
import 'package:student_projectry_app/model/Employeedetails.dart';

import 'package:student_projectry_app/Services/services.dart';

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
  void setSection(String? section) {
    setState(() {
      selectedSection = section;
      Navigator.pop(context); // Close drawer
    });
  }

  void editbox(DocumentSnapshot doc) {
    namecont.text = doc['name'];
    numbercont.text = doc['number'];
    statecont.text = doc['state'];
    salarycont.text = doc['salary'];
    sectioncont.text = doc['section'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("edit employee"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              SizedBox(height: 5,),
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
                    context: context,
                  );
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Employees",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text(
                "Section",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
            ),
            ListTile(
              title: Text(
                "All",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection(null),
            ),
            ListTile(
              title: Text(
                "Admin office",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Admin office"),
            ),
            ListTile(
              title: Text(
                "Anchor",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Anchor"),
            ),
            ListTile(
              title: Text(
                "Fancy",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Fancy"),
            ),
            ListTile(
              title: Text(
                "KK",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("KK"),
            ),
            ListTile(
              title: Text(
                "Soldering",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Soldering"),
            ),
            ListTile(
              title: Text(
                "Wire",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Wire"),
            ),
            ListTile(
              title: Text(
                "Joint",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Joint"),
            ),
            ListTile(
              title: Text(
                "V chain",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("V chain"),
            ),
            ListTile(
              title: Text(
                "Cutting",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Cutting"),
            ),
            ListTile(
              title: Text(
                "Box chain",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Box chain"),
            ),
            ListTile(
              title: Text(
                "Polish",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onTap: () => setSection("Polish"),
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
            final docs = snapshot.data!.docs;

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
                        "${emp.name}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Contact-${emp.number}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
