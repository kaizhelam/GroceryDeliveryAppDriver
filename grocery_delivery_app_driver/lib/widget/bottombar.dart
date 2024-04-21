import 'package:flutter/material.dart';

class bottomBarScreen extends StatefulWidget {
  const bottomBarScreen({super.key});

  @override
  State<bottomBarScreen> createState() => _bottomBarScreenState();
}

class _bottomBarScreenState extends State<bottomBarScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
      ),
    );
  }
}
