import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart'; // For enhanced typography
import 'package:permission_handler/permission_handler.dart'; // Import permission handler

class Hospital {
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  Hospital({
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  double distanceFrom(Position position) {
    const earthRadius = 6371; // km
    double dLat = _deg2rad(latitude - position.latitude);
    double dLon = _deg2rad(longitude - position.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(position.latitude)) * cos(_deg2rad(latitude)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;
}

class NearbyHospitalsPage extends StatefulWidget {
  @override
  _NearbyHospitalsPageState createState() => _NearbyHospitalsPageState();
}

class _NearbyHospitalsPageState extends State<NearbyHospitalsPage> {
  final List<Hospital> _hospitals = [
    // Sample hospitals in Mangalore (with corrected coordinates)
    Hospital(name: 'KMC Hospital, Mangalore', address: 'Jyothi Circle, Balmatta, Mangaluru', phone: '08242885533', latitude: 12.8648, longitude: 74.8456),
    Hospital(name: 'Yenepoya Specialty Hospital', address: 'Deralakatte, Mangaluru', phone: '08242206000', latitude: 12.8571, longitude: 74.9057),
    Hospital(name: 'A.J. Hospital & Research Centre', address: 'Kuntikana, Mangaluru', phone: '08246699999', latitude: 12.9144, longitude: 74.8553),
    Hospital(name: 'Father Muller Medical College Hospital', address: 'Kankanady, Mangaluru', phone: '08242238300', latitude: 12.8788, longitude: 74.8507),
    Hospital(name: 'Indiana Hospital & Heart Institute', address: 'Pumpwell Circle, Mangaluru', phone: '08244288888', latitude: 12.8885, longitude: 74.8689),
    // Adding the previously provided generic hospitals as well
    Hospital(name: 'Local Clinic', address: 'Main Street, Anytown', phone: '111222333', latitude: 12.9716, longitude: 77.5946),
    Hospital(name: 'Community Health Center', address: 'Town Square', phone: '444555666', latitude: 12.9352, longitude: 77.6142),
    Hospital(name: 'Metro Hospital', address: 'Outer Ring Road', phone: '777888999', latitude: 12.9611, longitude: 77.6387),
  ];
  Position? _currentPosition;
  List<Hospital> _nearbyHospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location services are disabled. Please enable them in your device settings.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location permissions are permanently denied. Please enable them in app settings.';
      });
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are denied.';
        });
        return;
      }
    }

    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _nearbyHospitals = _hospitals.where((h) => h.distanceFrom(position) <= 50).toList()
          ..sort((a, b) => a.distanceFrom(position).compareTo(b.distanceFrom(position))); // Sort by distance
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching location: $e';
      });
    }
  }

  Future<void> _callHospital(String phone) async {
    final url=Uri(
      scheme: 'tel',
      path: phone
    );
    
    try{
      await launchUrl(url);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
        
  }

  Future<void> _openMap(double latitude, double longitude, String name) async {
    final encodedName = Uri.encodeComponent(name);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude ($encodedName)';
    final appleUrl = 'http://maps.apple.com/?ll=$latitude,$longitude&q=$encodedName';

    final Uri googleUri = Uri.parse(googleUrl);
    final Uri appleUri = Uri.parse(appleUrl);

    try{
      await launchUrl(googleUri);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Hospitals', style: GoogleFonts.raleway(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: Colors.indigo.shade400, // A more prominent and thematic color
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade400)),
              SizedBox(height: 30),
              Text("Wait until we fetch the nearest hospital for you ..")
            ],
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        )
            : _nearbyHospitals.isEmpty
            ? Center(
          child: Text(
            'No hospitals found within 50 km.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
        )
            : ListView.separated(
          itemCount: _nearbyHospitals.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
          itemBuilder: (context, index) {
            final hospital = _nearbyHospitals[index];
            final distance = _currentPosition != null
                ? hospital.distanceFrom(_currentPosition!).toStringAsFixed(2)
                : 'N/A';
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
              child: InkWell( // Use InkWell for tap effect on the entire card
                onTap: () => _openMap(hospital.latitude, hospital.longitude, hospital.name),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        hospital.name,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.address,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '$distance km away',
                            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _callHospital(hospital.phone),
                            icon: const Icon(Icons.call, color: Colors.white, size: 16),
                            label: Text('Call', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade400,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}