import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningScreen extends StatefulWidget {
  final String driverId;

  const EarningScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  DateTime _selectedDate = DateTime.now();
  double totalEarnings = 0.0;
  int earningsDataLength = 0; // Variable to store the length of earnings data

  @override
  void initState() {
    super.initState();
    fetchTotalEarnings();
  }

  Future<void> fetchTotalEarnings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverId)
          .get();
      if (snapshot.exists) {
        final List<dynamic>? earningsData = snapshot['earnings'];

        if (earningsData != null) {
          // Filter earnings for the selected date
          final earningsForSelectedDate = earningsData.where((earning) {
            DateTime earningDate =
                (earning['currentDateTime'] as Timestamp).toDate();
            return earningDate.year == _selectedDate.year &&
                earningDate.month == _selectedDate.month &&
                earningDate.day == _selectedDate.day;
          }).toList();

          // Calculate total earnings for the selected date
          totalEarnings = earningsForSelectedDate.fold(
              0.0, (sum, earning) => sum + (earning['profitEarning'] ?? 0.0));

          // Update earnings data length
          earningsDataLength = earningsForSelectedDate.length;
        }
      } else {
        print('Driver document not found');
      }
    } catch (error) {
      print('Error fetching earnings: $error');
    }
    setState(
        () {}); // Update the UI with the total earnings and earnings data length
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), // Allow selection from the year 2000
      lastDate: DateTime.now(), // Allow selection up to the year 2100
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Colors.cyan),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        // Reset totalEarnings and earningsDataLength when date changes
        totalEarnings = 0.0;
        earningsDataLength = 0;
      });
      fetchTotalEarnings(); // Fetch earnings for the selected date
    }
  }

  Future<void> _viewAllTask(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "All Accepted Orders",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          content: FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('drivers')
                .doc(widget.driverId)
                .get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (productSnapshot.hasError) {
                return Center(child: Text('Error: ${productSnapshot.error}'));
              }
              if (!productSnapshot.hasData || !productSnapshot.data!.exists) {
                return const Center(child: Text('Product not found'));
              }

              // Fetch the ratingReview array from the product document
              final List<dynamic> earningArray =
                  productSnapshot.data!['earnings'];

              if (earningArray.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0,
                  child: const Center(
                    child: Text(
                      'No orders available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: earningArray.map((earn) {
                    final String name = earn['userName'] ?? '';
                    final String productName = earn['productName'] ?? '';
                    final String userLocation = earn['userLocation'] ?? '';

                    final Timestamp timestamp = earn['currentDateTime'];
                    final double earning = earn['profitEarning'];

                    String formattedDateTime = '';

                    if (timestamp != null) {
                      final DateTime dateTime = timestamp.toDate();
                      final DateTime dateTimePlus8Hours =
                          dateTime.add(Duration(hours: 8));
                      formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(dateTimePlus8Hours);
                    }

                    final String productImage = earn['productImage'] ?? '';
                    final int productQuantity = earn['productQuantity'] ?? '';
                    final String userAddress = earn['userLocation'] ?? '';

                    return ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("UserName : $name",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13)),
                          Text("Delivery to : $userAddress",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13)),
                          Text("Item : $productName",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13)),
                          Text("Quantity : X$productQuantity",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 13)),
                          Text(
                            "DateTime: $formattedDateTime",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 13),
                          ),
                          Text.rich(
                            TextSpan(
                              text: "Earn: RM ",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 15),
                              children: <TextSpan>[
                                TextSpan(
                                  text: earning.toStringAsFixed(
                                      2), // Formats to 2 decimal places
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewTotalEarnings(BuildContext context) async {
    double totalEarnings = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverId)
          .get();
      if (snapshot.exists) {
        final List<dynamic>? earningsData = snapshot['earnings'];

        if (earningsData != null) {
          // Calculate total earnings from all earnings data
          totalEarnings = earningsData.fold(
              0.0, (sum, earning) => sum + (earning['profitEarning'] ?? 0.0));
        }
      } else {
        print('Driver document not found');
      }
    } catch (error) {
      print('Error fetching earnings: $error');
    }

    // Display the total earnings in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Total Earnings'),
          content: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RM ${totalEarnings.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: TextStyle(color: Colors.cyan),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Earning',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 10), // Add some spacing
            Text(
              'Total Earnings for today: RM ${totalEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Total Delivery Time for today: $earningsDataLength',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: Icon(Icons.calendar_today),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan), // Green background color
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white), // White text color
              ),
              label: Text('Pick Date'),
            ),
            SizedBox(
              height: 15,
            ),
            ElevatedButton.icon(
              onPressed: () => _viewAllTask(context),
              icon: Icon(Icons.task),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan), // Green background color
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white), // White text color
              ),
              label: Text('View All Accepted Orders Details'),
            ),
            SizedBox(
              height: 15,
            ),
            ElevatedButton.icon(
              onPressed: () => _viewTotalEarnings(context),
              icon: Icon(Icons.attach_money),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan), // Green background color
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white), // White text color
              ),
              label: Text('View Total Earnings'),
            ),
          ],
        ),
      ),
    );
  }
}
