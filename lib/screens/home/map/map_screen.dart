import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Location location = new Location();
  final Firestore _firestore = Firestore.instance;
  final Geolocator _geolocator = Geolocator();
  final TextEditingController _addressTextController = TextEditingController();
  final String googleAPIKey = "AIzaSyA0gnpxGUi6nCT-W8YpefhEFOU8ml0Wt54";
  GoogleMapController mapController;
  List<Marker> allMarkers = [];
  var _markerId = 0;
  String searchAddress = "";
  List<Placemark> destination = [];
  LatLng currentLocation;
  LatLng destinationLocation;
  List<Polyline> _polylines = [];
  List<LatLng> routeCoords = [];
  PolylinePoints polylinePoints = PolylinePoints();
  var _destinationMarkersCount = 0;
  BitmapDescriptor potholeIcon;

  void setPotholeIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(1, 1)), "assets/icons8-p-26.png")
        .then((onValue) {
      potholeIcon = onValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children;
    return Scaffold(
      body: FutureBuilder(
          future: _setCurrentLocation(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Stack(
                children: <Widget>[
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target:
                            currentLocation,
                        zoom: 15),
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                    mapType: MapType.normal,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: Set<Marker>.from(allMarkers),
                    polylines: Set<Polyline>.from(_polylines),
                    onTap: (argument) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                  ),
                  Positioned(
                    top: 60.0,
                    right: 15.0,
                    left: 15.0,
                    child: Container(
                      height: 50.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Enter Destination",
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.only(left: 15.0, top: 15.0),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),                            
                            onPressed: () {
                              if (searchAddress != "") {
                                _setDestinationAndNavigate(); 
                              }
                              _addressTextController.clear();
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                            },
                            iconSize: 30.0,
                          ),
                        ),
                        controller: _addressTextController,
                        enableSuggestions: true,
                        onChanged: (value) {
                          setState(() {
                            searchAddress = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              children = <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                )
              ];
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              );
            } else {
              children = <Widget>[
                SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Loading Map...'),
                )
              ];
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: children,
                ),
              );
            }
          }),
    );
  }

  @override
  void initState() {
    super.initState();
    _animateToUserLocation();
    _initializeMarkers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeMarkers() async {
    setState(() {
      allMarkers = [];
    });
    setPotholeIcon();
    QuerySnapshot querySnapshot =
        await _firestore.collection("locations").getDocuments();

    querySnapshot.documents.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.data['position']['geopoint'];
      setState(() {
        allMarkers.add(
          Marker(
            markerId: MarkerId("$_markerId"),
            position: LatLng(pos.latitude, pos.longitude),
            icon: potholeIcon,
            visible: true,
          ),
        );
        _markerId++;
      });
    });
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  Future _setCurrentLocation() async {
    var value = await location.getLocation();
    setState(() {
      currentLocation = LatLng(value.latitude, value.longitude);
    });
    return currentLocation;
  }

  _setDestinationAndNavigate() {
    _geolocator
        .placemarkFromAddress(searchAddress)
        .then((result) {
          setState(() {
        destinationLocation =
            LatLng(result[0].position.latitude, result[0].position.longitude);
      });
    });
    _moveToDestinationLocation();
    setPolylines();
  }

  _moveToDestinationLocation() {
    var marker = Marker(
      markerId: MarkerId("$_markerId"),
      position:
          LatLng(destinationLocation.latitude, destinationLocation.longitude),
      icon:
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      visible: true,
    );
    setState(() {
      allMarkers.add(marker);
      _markerId++;
      _destinationMarkersCount++;
    });
     mapController.animateCamera(CameraUpdate.newLatLng(
      destinationLocation,
    ));
  }

  _animateToUserLocation() async {
    await mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLocation, zoom: 15)));
  }

  setPolylines() async {
    setState(() {
      _polylines = [];
      routeCoords = [];

      //remove previous destination marker
      if (_destinationMarkersCount > 1) {
        allMarkers.removeAt(allMarkers.length - 2);
      }
    });

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPIKey,
      PointLatLng(currentLocation.latitude, currentLocation.longitude),
      PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
      travelMode: TravelMode.driving,
    );
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        routeCoords.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print("###################################");
      print("Polyline result returned empty set!");
      print("###################################");
    }
    setState(() {
      
      Polyline polyline = Polyline(
        polylineId: PolylineId("poly"),
        color: Color.fromARGB(255, 40, 122, 198),
        points: routeCoords,
      );

      _polylines.add(polyline);
    });
  }
}