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
              SizedBox(height: 5),
              TextField(
                controller: sectioncont,
                decoration: InputDecoration(
                  hintText: "Section",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
               String? imageUrl;
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
                    TextField(
                      controller: sectioncont,
                      decoration: InputDecoration(
                        hintText: "Section",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
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
                            imageUrl: imageUrl??""
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
      body: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: StreamBuilder(
          stream: getemployees(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
           
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                Employee emp = Employee.fromMap(docs[index].data() as Map<String, dynamic>);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeDetailPage(employee: emp),));
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
    );
  }
}
