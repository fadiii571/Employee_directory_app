import 'package:flutter/material.dart';

class Imageviewesc extends StatelessWidget {
  final String profileImageUrl;
  const Imageviewesc({Key? key,required this.profileImageUrl}):super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   body: GestureDetector(
    onTap: () => Navigator.pop(context),
     child: InteractiveViewer(
      panEnabled: true,
      scaleEnabled: true,
      minScale: 0.6,
      maxScale: 5.0,
       child: Center(
        child: Image.network(profileImageUrl),
       ),
     ),
   ),
    );
  }
}