import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileScreen extends StatefulWidget {
  final String driverId;

  ProfileScreen({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController = TextEditingController();
  late TextEditingController _emailController = TextEditingController();
  late TextEditingController _phoneNumberController = TextEditingController();
  late TextEditingController _numberPlateController = TextEditingController();
  String _selectedVehicleType = 'Car'; // Default value

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchDriverDetails();
  }

  void _fetchDriverDetails() {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.driverId)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'];
          _emailController.text = doc['email'];
          _phoneNumberController.text = doc['phoneNumber'];
          _numberPlateController.text = doc['vehicleNumberPlate'];
          _selectedVehicleType = doc['vehicleType'] ?? 'Car'; // Set default value if null or invalid
        });
      }
    }).catchError((error) {
      print('Error fetching driver details: $error');
    });
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    final updatedName = _nameController.text;
    final updatedEmail = _emailController.text;
    final updatedPhoneNumber = _phoneNumberController.text;
    final updatedNumberPlate = _numberPlateController.text;
    final updatedVehicleType = _selectedVehicleType;

    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.driverId)
        .update({
      'email': updatedEmail,
      'name': updatedName,
      'phoneNumber': updatedPhoneNumber,
      'vehicleNumberPlate': updatedNumberPlate,
      'vehicleType': updatedVehicleType,
    }).then((_) {
      Fluttertoast.showToast(
          msg: "Profile Updated",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 13);
      _toggleEditing();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _toggleEditing,
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: _isEditing ? null : Colors.black),
            ),
            TextField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: _isEditing ? null : Colors.black),
            ),
            TextField(
              controller: _phoneNumberController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: _isEditing ? null : Colors.black),
            ),
            TextField(
              controller: _numberPlateController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Vehicle Number Plate',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: _isEditing ? null : Colors.black),
            ),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              onChanged: _isEditing
                  ? (newValue) {
                setState(() {
                  _selectedVehicleType = newValue!;
                });
              }
                  : null,
              items: ['Car', 'Motorcycle'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.black, fontSize: 18), // Set text color to black
                  ),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Vehicle Type',
                labelStyle: TextStyle(color: Colors.black),
              ),
              style: TextStyle(color: _isEditing ? null : Colors.black),
            ),
            if (_isEditing) SizedBox(height: 20),
            if (_isEditing)
              ElevatedButton(
                onPressed: _saveChanges,
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.cyan),
                  foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.white),
                ),
                child: Text('Save Changes'),
              ),
          ],
        ),
      ),
    );
  }
}
