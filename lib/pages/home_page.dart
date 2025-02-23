import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/map_marker.dart';

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  Location location = Location();
  LocationData? currentLocation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define the initial camera position
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.4221, -122.0841),
    zoom: 15,
  );

  // ADD MARKER BUTTON CONFIGURATION
  // dropdown menu for marker name and danger level
  final List<String> _dangerLevels = [
    'Level 1 - Low Risk: Proceed with caution', 
    'Level 2 - Medium Risk: Avoid area if possible', 
    'Level 3 - High Risk: Avoid area at all costs',
    ];
  final List<String> _nameOptions = [
    'Car Accident', 
    'Physical Threat', 
    'Armed Threat',
    'Theft/Vandalism',
    'Fire',
    'Stalker/Suspicious Person',
    'Other'
    ];

  // Form controllers
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String? _selectedName;
  String? _selectedDanger;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _listenToMarkers(); // This will start listening to Firebase updates
  }

  Future<void> _initializeLocation() async {
    try {
      // Request permission first
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      // Get location
      currentLocation = await location.getLocation();
      
      if (currentLocation != null) {
        // Update form fields
        _latController.text = currentLocation!.latitude!.toString();
        _lngController.text = currentLocation!.longitude!.toString();

        // If controller is initialized, move camera
        if (_controller != null) {
          _controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  currentLocation!.latitude!,
                  currentLocation!.longitude!,
                ),
                zoom: 15,
              ),
            ),
          );
          _searchNearbyPlaces();
        }
      }
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (currentLocation == null) return; // idk how this is working

    final String apiKey = 'YOUR_API_KEY'; // idk how this is working
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
      //print('Error searching nearby places: $e');  // for testing
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    if (currentLocation != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentLocation!.latitude!,
              currentLocation!.longitude!,
            ),
            zoom: 15,
          ),
        ),
      );
      _searchNearbyPlaces();
    }
  }

  // Open marker from form
  // Function to open the marker form
  void _openAddMarkerForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(
            EdgeInsets.all(16.0),
          ),
          child: Wrap(
            runSpacing: 15,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 8, bottom: 16),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Add Marker',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _latController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _lngController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedName,
                decoration: InputDecoration(
                  labelText: 'Category',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                items: _nameOptions
                    .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedName = value;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedDanger,
                decoration: InputDecoration(
                  labelText: 'Danger Level',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                items: _dangerLevels
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDanger = value;
                  });
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _addMarker();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Add Marker'),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Add marker using values from form
  void _addMarker() async {
    double? lat = double.tryParse(_latController.text);
    double? lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null || _selectedName == null || _selectedDanger == null) {
      return;
    }

    try {
      // First add to Firestore
      await _firestore.collection('markers').add({
        'latitude': lat,
        'longitude': lng,
        'name': _selectedName,
        'dangerLevel': _selectedDanger,
        'description': _descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear form fields for next marker
      setState(() {
        _selectedName = null;
        _selectedDanger = null;
        _descriptionController.clear();
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marker added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding marker: $e');
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add marker: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _listenToMarkers() {
    _firestore.collection('markers')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) {
        setState(() {
          // Only clear user-added markers, not Places API markers
          _markers.removeWhere((marker) => 
            marker.markerId.value.startsWith('user_'));
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final String dangerLevel = data['dangerLevel'] as String;
            final marker = Marker(
              markerId: MarkerId('user_${doc.id}'),
              position: LatLng(
                data['latitude'] as double,
                data['longitude'] as double
              ),
              infoWindow: InfoWindow(
                title: data['name'] as String,
                snippet: 'Danger: $dangerLevel\n${data['description'] ?? ''}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerHue(dangerLevel)
              ),
            );
            _markers.add(marker);
          }
        });
    }, onError: (error) {
      print('Error listening to markers: $error');
    });
  }

  double _getMarkerHue(String dangerLevel) {
    if (dangerLevel.contains('Level 1')) {
      return BitmapDescriptor.hueYellow;
    } else if (dangerLevel.contains('Level 2')) {
      return BitmapDescriptor.hueOrange;
    } else if (dangerLevel.contains('Level 3')) {
      return BitmapDescriptor.hueRed;
    }
    return BitmapDescriptor.hueAzure;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _searchNearbyPlaces,
          ), // IconButton
        ],
      ),  // AppBar
      body: GoogleMap(
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: false, // hide zoom buttons
        onMapCreated: _onMapCreated,
        initialCameraPosition: currentLocation != null
            ? CameraPosition(
                target: LatLng(
                  currentLocation!.latitude!,
                  currentLocation!.longitude!,
                ),
                zoom: 15,
              )
            : _initialPosition,
        markers: _markers,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,      
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 69.0), // lol
        child: FloatingActionButton(
          onPressed: _openAddMarkerForm,
          child: Icon(Icons.add_location_alt),
        ),
      ), // padding for button
    ); // Scaffold
  }
}

