//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late GoogleMapController _controller;
  final Set<Marker> _markers = {};
  Location location = Location();
  LocationData? currentLocation;

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
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      currentLocation = await location.getLocation();
      if (currentLocation != null) {
        // Get current location for form fields
        _latController.text = currentLocation!.latitude!.toString();
        _lngController.text = currentLocation!.longitude!.toString();        

        _controller.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
          ),
        );
        _searchNearbyPlaces();
      }
    } catch (e) {
      //print('Error getting location: $e');  // for testing
    }
  }

  Future<void> _searchNearbyPlaces() async {
    if (currentLocation == null) return;

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
    _getCurrentLocation();
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
  void _addMarker() {
    double? lat = double.tryParse(_latController.text);
    double? lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null || _selectedName == null || _selectedDanger == null) {
      // You can show an error using a Snackbar or Dialog if desired.
      return;
    }

    // Choose marker hue based on danger level
    double markerHue;
    switch (_selectedDanger) {
      case 'Level 1 - Low Risk: Proceed with caution':
        markerHue = BitmapDescriptor.hueYellow;
        break;
      case 'Level 2 - Medium Risk: Avoid area if possible':
        markerHue = BitmapDescriptor.hueOrange;
        break;
      case 'Level 3 - High Risk: Avoid area at all costs':
        markerHue = BitmapDescriptor.hueRed;
        break;
      default:
        markerHue = BitmapDescriptor.hueAzure;
    }

    final Marker marker = Marker(
      markerId: MarkerId(DateTime.now().millisecondsSinceEpoch.toString()),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: _selectedName,
        snippet: 'Danger: $_selectedDanger${_descriptionController.text.isNotEmpty ? '\n${_descriptionController.text}' : ''}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
    );

    setState(() {
      _markers.add(marker);
    });

    // Clear form fields for next marker
    _selectedName = null;
    _selectedDanger = null;
    _descriptionController.clear();
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
        initialCameraPosition: _initialPosition,
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

