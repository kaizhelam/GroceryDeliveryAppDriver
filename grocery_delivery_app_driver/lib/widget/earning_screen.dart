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
  int earningsDataLength = 0;

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
          final earningsForSelectedDate = earningsData.where((earning) {
            DateTime earningDate =
                (earning['currentDateTime'] as Timestamp).toDate();
            return earningDate.year == _selectedDate.year &&
                earningDate.month == _selectedDate.month &&
                earningDate.day == _selectedDate.day;
          }).toList();
          totalEarnings = earningsForSelectedDate.fold(0.0, (sum, earning) => sum + (earning['profitEarning'] ?? 0.0));
          earningsDataLength = earningsForSelectedDate.length;
        }
      } else {
        print('Driver document not found');
      }
    } catch (error) {
      print('Error fetching earnings: $error');
    }
    setState(
        () {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.cyan),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        totalEarnings = 0.0;
        earningsDataLength = 0;
      });
      fetchTotalEarnings();
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
                          dateTime.add(const Duration(hours: 8));
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

  Future<double> _fetchTotalEarnings() async {
    double totalEarnings = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driverId)
          .get();
      if (snapshot.exists) {
        final List<dynamic>? earningsData = snapshot['earnings'];

        if (earningsData != null) {
          totalEarnings = earningsData.fold(
              0.0, (sum, earning) => sum + (earning['profitEarning'] ?? 0.0));
        }
      } else {
        print('Driver document not found');
      }
    } catch (error) {
      print('Error fetching earnings: $error');
    }

    return totalEarnings;
  }

  void _showTotalEarningsDialog(BuildContext context, double totalEarnings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Total Earnings'),
          content: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'RM ${totalEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
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
              child: const Text('Close', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _viewTotalEarnings(BuildContext context) async {
    double totalEarnings = await _fetchTotalEarnings();

    if (context.mounted) {
      _showTotalEarningsDialog(context, totalEarnings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Earnings for today: RM ${totalEarnings.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Total Delivery Time for today: $earningsDataLength',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan),
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white),
              ),
              label: const Text('Pick Date'),
            ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton.icon(
              onPressed: () => _viewAllTask(context),
              icon: const Icon(Icons.task),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan),
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white),
              ),
              label: const Text('View All Accepted Orders Details'),
            ),
            const SizedBox(
              height: 15,
            ),
            ElevatedButton.icon(
              onPressed: () => _viewTotalEarnings(context),
              icon: const Icon(Icons.attach_money),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.cyan),
                foregroundColor: MaterialStateProperty.all<Color>(
                    Colors.white),
              ),
              label: const Text('View Total Earnings'),
            ),
          ],
        ),
      ),
    );
  }
}
