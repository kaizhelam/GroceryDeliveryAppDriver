import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app_driver/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _driverIdController = TextEditingController();
  bool _isLoading = false; // Add a boolean to track loading state

  @override
  void dispose() {
    _driverIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GoGrocery Merchant', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.cyan,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 60.0),
              child: Opacity(
                opacity: _isLoading ? 0.0 : 1.0,
                child: Card(
                  color: Colors.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Welcome back text
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10.0), // Adjust the spacing between title and subtitle
                              Text(
                                'Please enter your Driver ID to login',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.0),
                        // Driver icon
                        Icon(
                          Icons.delivery_dining_rounded,
                          size: 150.0,
                          color: Colors.white,
                        ),
                        SizedBox(height: 20.0),
                        // Text field for driver ID
                        TextField(
                          controller: _driverIdController,
                          decoration: InputDecoration(
                            labelText: 'Driver ID',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 25.0),
                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _loginUser(),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                            foregroundColor: MaterialStateProperty.all<Color>(Colors.cyan),
                          ),
                          child: Text('Login', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.cyan,
              ),
            ),
        ],
      ),
    );
  }


  void _loginUser() {
    setState(() {
      _isLoading = true; // Set loading state to true when user clicks login button
    });

    String driverId = _driverIdController.text.trim();
    if (driverId.isEmpty) {
      Fluttertoast.showToast(
          msg: "Please key in your Driver ID",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 13);
      setState(() {
        _isLoading = false;
      });
    } else {
      FirebaseFirestore.instance.collection('drivers').get().then((querySnapshot) {
        bool isDriverFound = false;
        String driverName = "";
        String driverEmail = "";
        String driverPhoneNumber = "";
        String driverid = "";
        querySnapshot.docs.forEach((doc) {
          if (doc.data()['driverId'] == driverId) {
            driverid = doc.data()['driverId'];
            isDriverFound = true;
            Fluttertoast.showToast(
                msg: "Logged In...",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey[200],
                textColor: Colors.black,
                fontSize: 13);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen(driverId: driverid)),
            );
          }
        });
        if (!isDriverFound) {
          Fluttertoast.showToast(
              msg: "Invalid Driver ID",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 13);
        }
        setState(() {
          _isLoading = false; // Set loading state back to false
        });
      }).catchError((error) {
        // Error fetching data from Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false; // Set loading state back to false
        });
      });
    }
  }
}