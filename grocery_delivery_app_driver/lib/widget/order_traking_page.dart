import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grocery_delivery_app_driver/main.dart';
import 'package:grocery_delivery_app_driver/widget/constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:grocery_delivery_app_driver/widget/earning_screen.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({
    Key? key,
    required this.lat,
    required this.long,
    required this.orderId,
    required this.driverId,
  }) : super(key: key);

  final double lat;
  final double long;
  final String orderId;
  final String driverId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation =
      LatLng(2.2338, 102.2825); // starting point
  late LatLng userDestination; // user destination

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen(
      (newLoc) {
        currentLocation = newLoc;
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              zoom: 13.5,
              target: LatLng(
                newLoc.latitude!,
                newLoc.longitude!,
              ),
            ),
          ),
        );
        setState(() {});
      },
    );
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      google_api_key,
      travelMode: TravelMode.driving,
      optimizeWaypoints: true,
      PointLatLng(userDestination.latitude, userDestination.longitude),
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});
    }
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      "assets/images/Badge.png",
    ).then((icon) {
      sourceIcon = icon;
    });
  }

  @override
  void initState() {
    userDestination = LatLng(widget.lat, widget.long);
    getCurrentLocation();
    setCustomMarkerIcon();
    getPolyPoints();
    super.initState();
    setState(() {});
    _checkArrival(context);
  }

  StreamSubscription<LocationData>? locationSubscription;

  void dispose() {
    locationSubscription?.cancel();
    _controller.future.then((controller) => controller.dispose());
    super.dispose();
  }

  bool isLoading = false;

  void _refreshPage() {
    setState(() {
      isLoading = true;
    });
    setState(() {
      isLoading = false;
    });
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double radiusEarth = 6371; double lat1 = _toRadians(point1.latitude);double lon1 = _toRadians(point1.longitude);double lat2 = _toRadians(point2.latitude);
    double lon2 = _toRadians(point2.longitude);
    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;
    double a = pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    double c = 2 * asin(sqrt(a));
    return radiusEarth * c;
  }
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
  final double arrivalThreshold = 0.17;
  double distance = 0.0; String formattedArrivalTime = ""; final double averageSpeed = 30;
  void _checkArrival(BuildContext context) {
    if (currentLocation != null && userDestination != null) {
      double distanceToDestination = calculateDistance(LatLng(currentLocation!.latitude!, currentLocation!.longitude!), userDestination!,
      );
      if (distanceToDestination <= arrivalThreshold) {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
          'orderStatus': 3,
        }).then((value) {
          Future.delayed(const Duration(seconds: 4), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(driverId: widget.driverId),
              ),
            );
            Fluttertoast.showToast(
              msg: "Product Delivery & Arrived Destination",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 2,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 13,
            );
          });
        }).catchError((error) {
          print('Error updating document: $error');
        });
      } else {
        print('On the way going');
      }
    } else {
      print('Current location or user destination is null.');
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkArrival(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : currentLocation == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _refreshPage,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.cyan,
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                      Colors.white,
                    ),
                  ),
                  child: const Text(
                    "Open Live Google Map & Navigate to User Destination",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            : GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              currentLocation!.latitude!,
              currentLocation!.longitude!,
            ),
            zoom: 13.5,
          ),
          polylines: {
            Polyline(
              polylineId: const PolylineId("route"),
              points: polylineCoordinates,
              color: primaryColor,
              width: 6,
            ),
          },
          markers: {
            Marker(
              markerId: const MarkerId("currentLocation"),
              icon: sourceIcon,
              position: LatLng(
                currentLocation!.latitude!,
                currentLocation!.longitude!,
              ),
            ),
            Marker(
              markerId: const MarkerId("source"),
              position: userDestination,
            ),
            const Marker(
              markerId: MarkerId("destination"),
              position: sourceLocation,
            ),
          },
          onMapCreated: (mapController) {
            _controller.complete(mapController);
          },
        ),
      ),
    );
  }
}
