import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:grocery_delivery_app_driver/widget/constants.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({
    Key? key,
    required this.lat,
    required this.long,
  }) : super(key: key);

  final double lat;
  final double long;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  late LatLng sourceLocation;
  static const LatLng destination = LatLng(2.2536, 102.2815);

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
              zoom: 16,
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
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
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
    sourceLocation = LatLng(widget.lat, widget.long);
    getCurrentLocation();
    setCustomMarkerIcon();
    getPolyPoints();
    super.initState();
    setState(() {

    });
  }

  StreamSubscription<LocationData>? locationSubscription;

  void dispose() {
    locationSubscription?.cancel();
    _controller.future.then((controller) => controller.dispose());
    super.dispose();
  }

  void _refreshPage() {
    setState(() {
      // Refresh logic here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Track Order",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPage,
          ),
        ],
      ),
      body: currentLocation == null
          ? const Center(child: Text("Loading... it may takes some times \ntap the refresh button \nto quickly track the location."))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
          ),
          zoom: 16,
        ),
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: polylineCoordinates,
            color: primaryColor,
            width: 6,
          ),
        },
        markers: {
          Marker(
            markerId: MarkerId("currentLocation"),
            icon: sourceIcon,
            position: LatLng(
              currentLocation!.latitude!,
              currentLocation!.longitude!,
            ),
          ),
          Marker(
            markerId: MarkerId("source"),
            position: sourceLocation,
          ),
          Marker(
            markerId: MarkerId("destination"),
            position: destination,
          ),
        },
        onMapCreated: (mapController) {
          _controller.complete(mapController);
        },
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: OrderTrackingPage(),
//   ));
// }
