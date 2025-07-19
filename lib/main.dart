import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_projectry_app/homesc.dart';
import 'package:student_projectry_app/splash.dart';
import 'firebase_options.dart';
void main()async {


await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData( textTheme: TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
      bodyMedium: TextStyle(fontSize: 17, color: Colors.black),
      bodySmall: TextStyle(fontSize: 14, color: Colors.black),
    ),

        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: Splashh()
    );
  }
}


