import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grocery_delivery_app_driver/widget/order_traking_page.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class dashboardScreen extends StatefulWidget {
  const dashboardScreen({super.key});

  @override
  State<dashboardScreen> createState() => _dashboardScreenState();
}

class _dashboardScreenState extends State<dashboardScreen> {
  @override
  void initState() {
    tz.initializeTimeZones();
    updateTimePeriodically();
    super.initState();
  }

  void updateTimePeriodically() {
    Timer.periodic(Duration(seconds: 60), (timer) {
      setState(() {
        // Update the UI with the current time
        // Call getCurrentTime to fetch the current time
        getCurrentTime(_timeZone).then((time) {
          // Update the UI with the new time
        });
      });
    });
  }

  String _timeZone = 'Asia/Kuala_Lumpur'; // Set timezone to Malaysia

  String _formatDateAndTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    dateTime = dateTime.add(Duration(hours: 8)); // Add 8 hours
    String formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(dateTime);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, top: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Driver',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder<tz.TZDateTime?>(
                  future: getCurrentTime(_timeZone),
                  builder: (context, AsyncSnapshot<tz.TZDateTime?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      if (snapshot.data != null) {
                        return Text(
                          'Current Date & Time: ${_formatDateTime(snapshot.data!)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        );
                      } else {
                        return Text('No data available');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              color: Colors.white.withOpacity(0.9),
              margin: EdgeInsets.all(13),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10, top: 13, right: 10, bottom: 0),
                    child: Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 10,
                  ),
                  SizedBox(height: 5),
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else {
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Text('No orders available'),
                            );
                          } else {
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
                                String imageUrl = data['imageUrl'];
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Order Details'),
                                          content: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(data['title'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text('Quantity : ${data['quantity']}'),
                                              Text('Price : RM ${data['price']?.toStringAsFixed(2) ?? ''}'),
                                              Text('Order Date: ${_formatDateAndTime(data['orderDate'])}'),
                                              SizedBox(height: 20),
                                              Text('User Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text('Name: ${data['userName']}'),
                                              Text('Email: ${data['phoneNumber']}'),
                                              Text('Address: ${data['shippingAddress']}'),
                                              SizedBox(height: 20),
                                              Text('Note Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text('Message: ${data['noteForDriver'].isEmpty ? 'Empty' : data['noteForDriver']}'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => OrderTrackingPage()),
                                                );
                                              },
                                              child: Text('Accept'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Cancel'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: Image.network(
                                      imageUrl,
                                      width: 80,
                                      height: 80,
                                    ),
                                    title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold),),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Quantity : ${data['quantity']}'),
                                        Text('Price : RM ${data['price']?.toStringAsFixed(2) ?? ''}'),
                                        Text(data['orderStatus'].toString() == '0' ? 'The order is pending' : 'The order is accepted'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<tz.TZDateTime> getCurrentTime(String timeZone) async {
    tz.Location location = tz.getLocation(timeZone);
    return await tz.TZDateTime.now(location);
  }

  String _formatDateTime(tz.TZDateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }
}