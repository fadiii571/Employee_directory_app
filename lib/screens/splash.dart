import 'package:flutter/material.dart';
import 'package:student_projectry_app/screens/homesc.dart';

class Splashh extends StatefulWidget {
  const Splashh({super.key});

  @override
  State<Splashh> createState() => _SplashhState();
}

class _SplashhState extends State<Splashh> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 4),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Home()));
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/logo.png",width: 700,),
          SizedBox(height: 70,),
          Text("Mentor",style: TextStyle(color: Colors.green,fontSize: 20,fontWeight: FontWeight.bold),)
        ],
      ),
    );
  }
}