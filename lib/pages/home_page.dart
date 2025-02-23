import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  Location location = Location();
  LocationData? currentLocation;

  // Define the initial camera position
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.4221, -122.0841),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      currentLocation = await location.getLocation();
      if (currentLocation != null) {
        _controller.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ),
        );
        _searchNearbyPlaces();
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (currentLocation == null) return;

    final String apiKey = 'YOUR_API_KEY'; // Use your Google Maps API key
    final String baseUrl = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    
    final String url = '$baseUrl?'
        'location=${currentLocation!.latitude},${currentLocation!.longitude}'
        '&radius=1500'  // Search within 1.5km
        '&type=store'   // Search for stores
        '&openNow=true' // Only show currently open places
        '&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _markers.clear();
          for (var place in data['results']) {
            final marker = Marker(
              markerId: MarkerId(place['place_id']),
              position: LatLng(
                place['geometry']['location']['lat'],
                place['geometry']['location']['lng'],
              ),
              infoWindow: InfoWindow(
                title: place['name'],
                snippet: place['vicinity'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            );
            _markers.add(marker);
          }
        });
      }
    } catch (e) {
      print('Error searching nearby places: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Map'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _searchNearbyPlaces,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

