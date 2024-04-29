import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_app_driver/widget/bottombar.dart';
import 'package:grocery_delivery_app_driver/widget/dashboard.dart';
import 'package:grocery_delivery_app_driver/widget/order_traking_page.dart';

import 'firebase_options.dart';

void main()async  {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter has initialized properly
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    dashboardScreen(),
    // OrderTrackingPage(lat: 1, long: 1),
    bottomBarScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(
            () {
              _currentIndex = index;
            },
          );
        },
        selectedItemColor: Colors.green,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.map),
          //   label: 'Tracking Order',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
