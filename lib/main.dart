import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_projectry_app/screens/homesc.dart';
import 'package:student_projectry_app/screens/splash.dart';

import 'firebase_options.dart';

/*Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("📩 Background message received: ${message.notification?.title}");
}*/
void main()async {
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
/*FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);*/

/*await FirebaseMessaging.instance.requestPermission();*/

/*await saveAdminFCMToken();*/
  runApp(const MyApp());
}

/*Future<void> saveAdminFCMToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    await FirebaseFirestore.instance
        .collection('admin')
        .doc('fcmToken')
        .set({'token': fcmToken});
  }
}*/


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData( 
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),

        
      
      
      debugShowCheckedModeBanner: false,
      home: Splashh()
    );
  }
}


