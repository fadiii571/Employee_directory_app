import 'package:flutter/material.dart';

class Loginsc extends StatefulWidget {
  const Loginsc({super.key});

  @override
  State<Loginsc> createState() => _LoginscState();
}

class _LoginscState extends State<Loginsc> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("LOGIN", style: TextStyle(color: Colors.black,fontSize: 22,fontWeight: FontWeight.bold)),
              TextField(
                decoration: InputDecoration(prefixIcon: Icon(Icons.email),
                hintText: "Username",
                filled: true,
                fillColor: Color.fromARGB(255, 235, 224, 224),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none
                )
          
                ),
              ),
              SizedBox(height: 10,),
              TextField(
                decoration: InputDecoration(prefixIcon: Icon(Icons.password_sharp),
                hintText: "Password",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}