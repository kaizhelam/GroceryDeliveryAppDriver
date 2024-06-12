import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_delivery_app_driver/widget/login.dart';
import 'package:grocery_delivery_app_driver/widget/order_traking_page.dart';
import 'package:intl/date_time_patterns.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class dashboardScreen extends StatefulWidget {
  final String driverId;

  const dashboardScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  State<dashboardScreen> createState() => _dashboardScreenState();
}

class _dashboardScreenState extends State<dashboardScreen> {
  String _driverName = '';

  @override
  void initState() {
    super.initState();
    fetchDriverName();
    tz.initializeTimeZones();
    updateTimePeriodically();
  }

  void fetchDriverName() {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(widget.driverId)
        .get()
        .then((doc) {
      if (doc.exists) {
        setState(() {
          _driverName = doc['name'];
        });
      }
    }).catchError((error) {
      print('Error fetching driver data: $error');
    });
  }

  void updateTimePeriodically() {
    Timer.periodic(const Duration(seconds: 60), (timer) {
      setState(() {
        getCurrentTime(_timeZone).then((time) {});
      });
    });
  }

  final String _timeZone = 'Asia/Kuala_Lumpur';

  String _formatDateAndTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    dateTime = dateTime.add(const Duration(hours: 8));
    String formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(dateTime);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Fluttertoast.showToast(
                  msg: "Signing Out...",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.grey[200],
                  textColor: Colors.black,
                  fontSize: 13);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.exit_to_app,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Hi, ',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: _driverName,
                        style: const TextStyle(
                          color: Colors.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<tz.TZDateTime?>(
                  future: getCurrentTime(_timeZone),
                  builder: (context, AsyncSnapshot<tz.TZDateTime?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      if (snapshot.data != null) {
                        return Text(
                          'Current Date & Time: ${_formatDateTime(snapshot.data!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        );
                      } else {
                        return const Text('No data available');
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
                  const Padding(
                    padding: EdgeInsets.only(
                        left: 10, top: 13, right: 10, bottom: 0),
                    child: Text(
                      'All Pending Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 10,
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .snapshots(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else {
                          final docs = snapshot.data?.docs ?? [];
                          final pendingOrders = docs
                              .where((doc) => doc['orderStatus'] == 1)
                              .toList();
                          if (pendingOrders.isEmpty) {
                            return const Center(
                              child: Text(
                                'No pending orders available',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          } else {
                            return ListView.builder(
                              itemCount: pendingOrders.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> data = pendingOrders[index]
                                    .data() as Map<String, dynamic>;
                                String imageUrl = data['imageUrl'];
                                double lat = data['lat'];
                                double long = data['long'];
                                String orderId = data['orderId'];

                                double earnings =
                                    (data['totalPayment'] * 0.4) ?? 0.0;
                                DateTime currentDate = DateTime.now();
                                DateTime currentDatePlus8Hours =
                                    currentDate.add(const Duration(hours: 0));

                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Order Details'),
                                          content: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(data['title'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17)),
                                              Text(
                                                  'Quantity : ${data['quantity']}'),
                                              Text(
                                                  'Order Date & Time: \n${_formatDateAndTime(data['orderDate'])}'),
                                              const SizedBox(height: 20),
                                              const Text('User Details',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17)),
                                              Text('Name: ${data['userName']}'),
                                              Text(
                                                  'Phone Number: ${data['phoneNumber']}'),
                                              Text(
                                                  'Address: ${data['shippingAddress']}'),
                                              const SizedBox(height: 20),
                                              const Text('Note Message',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17)),
                                              Text(
                                                  'Message: ${data['noteForDriver'].isEmpty ? 'Empty' : data['noteForDriver']}'),
                                              const SizedBox(height: 20),
                                              const Text('Payment Details',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17)),
                                              Text(
                                                  'Total Payment : RM ${data['totalPayment']?.toStringAsFixed(2) ?? ''}'),
                                              Text(
                                                  'Payment Method: ${data['paymentMethod']}'),
                                              Text(
                                                  'Earning: RM ${earnings.toStringAsFixed(2)}'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('orders')
                                                      .doc(orderId)
                                                      .update({
                                                    'orderStatus': 2,
                                                  });
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('drivers')
                                                      .doc(widget.driverId)
                                                      .update({
                                                    'earnings':
                                                        FieldValue.arrayUnion([
                                                      {
                                                        'productName':
                                                            data['title'],
                                                        'productQuantity':
                                                            data['quantity'],
                                                        'productImage':
                                                            imageUrl,
                                                        'userName':
                                                            data['userName'],
                                                        'userLocation': data[
                                                            'shippingAddress'],
                                                        'profitEarning':
                                                            earnings,
                                                        'currentDateTime':
                                                            currentDatePlus8Hours,
                                                      }
                                                    ])
                                                  });
                                                } catch (error) {
                                                  print(
                                                      'Error updating document: $error');
                                                }
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OrderTrackingPage(
                                                      lat: lat,
                                                      long: long,
                                                      orderId: orderId,
                                                      driverId: widget.driverId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                'Accept',
                                                style: TextStyle(
                                                    color: Colors.cyan),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    color: Colors.cyan),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: ListTile(
                                    leading: Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 120,
                                      // fit: BoxFit.cover,
                                    ),
                                    title: Text(
                                      data['title'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Quantity : ${data['quantity']}'),
                                        Text(
                                            'Total Payment : RM ${data['totalPayment']?.toStringAsFixed(2) ?? ''}'),
                                        Text(
                                            'Delivery to : ${data['shippingAddress']}'),
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
    return tz.TZDateTime.now(location);
  }

  String _formatDateTime(tz.TZDateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }
}
