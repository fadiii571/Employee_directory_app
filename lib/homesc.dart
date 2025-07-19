import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_projectry_app/services.dart';

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
    namecont.text=doc['name'];
    numbercont.text=doc['number'];
    statecont.text=doc['state'];
    salarycont.text=doc['salary'];
    sectioncont.text=doc['section'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(title: Text("edit employee"),content: Column(
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
                       updateemployee(id: doc.id, name: namecont.text, number: numbercont.text, state: statecont.text, salary: salarycont.text, section: sectioncont.text, context: context);
                      },
                      child: Text(
                        "Update Employee",
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
                  ],
                ),);
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
                    SizedBox(height: 10),
                    SizedBox(height:40 ,width: 160,
                      child: ElevatedButton(
                        onPressed: () {
                          Addemployee(
                            name: namecont.text,
                            number: numbercont.text,
                            state: statecont.text,
                            salary: salarycont.text,
                            section: sectioncont.text,
                            context: context,
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
        margin: EdgeInsets.symmetric(vertical: 5,horizontal: 10),
        decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(10)),
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
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8,horizontal: 4),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () {editbox(docs[index]);}, icon: Icon(Icons.edit)),
                        IconButton(
                          onPressed: () {
                            deletemp(docs[index].id);
                          },
                          icon: Icon(Icons.delete),
                        ),
                      ],
                    ),
                    title: Text("${docs[index]['name']}",style: Theme.of(context).textTheme.titleLarge,),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Contact-${docs[index]['number']}",style: Theme.of(context).textTheme.bodyMedium,),
                        Text("Section-${docs[index]['section']}",style: Theme.of(context).textTheme.bodyMedium,),
                        Text("Salary-₹${docs[index]['salary']}",style: Theme.of(context).textTheme.bodyMedium,),
                        Text("State-${docs[index]['state']}",style: Theme.of(context).textTheme.bodyMedium,),
                      ],
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
