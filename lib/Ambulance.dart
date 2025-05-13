import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class AmbulanceServicesPage extends StatefulWidget {
  const AmbulanceServicesPage({Key? key}) : super(key: key);

  @override
  _AmbulanceServicesPageState createState() => _AmbulanceServicesPageState();
}

class _AmbulanceServicesPageState extends State<AmbulanceServicesPage> {
  bool _isLoading = false;
  Position? _currentPosition;
  List<AmbulanceService> _ambulanceServices = [];
  List<AmbulanceService> _filteredServices = [];
  String _searchQuery = '';
  bool _showNearbyOnly = false;

  @override
  void initState() {
    super.initState();
    _loadAmbulanceServices();
    _getCurrentLocation();
  }

  void _loadAmbulanceServices() {
    // In a real app, this would come from an API or database
    _ambulanceServices = [
      AmbulanceService(
        id: '1',
        name: 'Quick Response Ambulance',
        address: '123 Main Street, Downtown',
        rating: 4.8,
        phoneNumber: '+1-555-123-4567',
        latitude: 37.7749,
        longitude: -122.4194,
        services: ['Advanced Life Support', 'Critical Care Transport', 'Neonatal Care'],
        available: true,
      ),
      AmbulanceService(
        id: '2',
        name: 'MedExpress Ambulance',
        address: '456 Oak Avenue, Westside',
        rating: 4.5,
        phoneNumber: '+1-555-765-4321',
        latitude: 37.7833,
        longitude: -122.4167,
        services: ['Basic Life Support', 'Emergency Transport'],
        available: true,
      ),
      AmbulanceService(
        id: '3',
        name: 'LifeLine Emergency Services',
        address: '789 Pine Road, Eastside',
        rating: 4.9,
        phoneNumber: '+1-555-987-2345',
        latitude: 37.7694,
        longitude: -122.4862,
        services: ['Advanced Life Support', 'Non-Emergency Transport', 'Critical Care'],
        available: false,
      ),
      AmbulanceService(
        id: '4',
        name: 'City Ambulance Corp',
        address: '321 Cedar Street, Northside',
        rating: 4.3,
        phoneNumber: '+1-555-345-6789',
        latitude: 37.7927,
        longitude: -122.4198,
        services: ['Emergency Transport', 'Inter-facility Transfer'],
        available: true,
      ),
      AmbulanceService(
        id: '5',
        name: 'Premier Medical Transport',
        address: '654 Maple Drive, Southside',
        rating: 4.7,
        phoneNumber: '+1-555-234-5678',
        latitude: 37.7586,
        longitude: -122.4120,
        services: ['Advanced Life Support', 'Bariatric Transport', 'Critical Care'],
        available: true,
      ),
      AmbulanceService(
        id: '6',
        name: 'Rapid Response Ambulance',
        address: '888 Market Street, Financial District',
        rating: 4.6,
        phoneNumber: '+1-555-456-7890',
        latitude: 37.7881,
        longitude: -122.4075,
        services: ['Basic Life Support', 'Emergency Transport', 'Event Medical Coverage'],
        available: true,
      ),
      AmbulanceService(
        id: '7',
        name: 'Golden Gate Medical Transport',
        address: '435 Balboa Street, Richmond District',
        rating: 4.4,
        phoneNumber: '+1-555-678-9012',
        latitude: 37.7765,
        longitude: -122.4657,
        services: ['Non-Emergency Transport', 'Wheelchair Transport', 'Basic Life Support'],
        available: true,
      ),
      AmbulanceService(
        id: '8',
        name: 'Bay Area Emergency Services',
        address: '230 California Street, Financial District',
        rating: 4.9,
        phoneNumber: '+1-555-890-1234',
        latitude: 37.7935,
        longitude: -122.4016,
        services: ['Advanced Life Support', 'Critical Care', '24/7 Emergency Response'],
        available: false,
      ),
      AmbulanceService(
        id: '10',
        name: 'Vishva Hindu Parishath Bajanrangadala',
        address: "Moodbidri mangalore ",
        rating: 4.9,
        phoneNumber: '+919112345623',
        latitude: 13.0688,
        longitude: 74.9936,
        services: ['Advanced Life Support', 'Critical Care', '24/7 Emergency Response'],
        available: true,
      )
    ];

    _filteredServices = List.from(_ambulanceServices);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show dialog to enable location services
        bool userAccepted = await _showLocationServiceDialog();
        if (userAccepted) {
          // Open location settings
          await Geolocator.openLocationSettings();
          // After returning from settings, check again
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            throw Exception('Location services are still disabled');
          }
        } else {
          throw Exception('Location services must be enabled to show nearby ambulance services');
        }
      }

      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Show dialog to open app settings
        bool userAccepted = await _showPermissionDeniedDialog();
        if (userAccepted) {
          await Geolocator.openAppSettings();
          throw Exception('Please grant location permissions from settings');
        } else {
          throw Exception('Location permissions are required to show nearby ambulance services');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        if (_showNearbyOnly) {
          _filterServices();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _getCurrentLocation,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showLocationServiceDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text(
              'This app needs location access to find nearby ambulances. '
                  'Please enable location services to continue.'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('ENABLE'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade800,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showPermissionDeniedDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Required'),
          content: Text(
              'This app needs location access to find nearby ambulances. '
                  'Please grant permission from app settings.'
          ),
          actions: <Widget>[
            TextButton(
              child: Text('NOT NOW'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('OPEN SETTINGS'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade800,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _filterServices() {
    setState(() {
      _filteredServices = _ambulanceServices.where((service) {
        // Filter by search query
        bool matchesSearch = service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.address.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filter by proximity if needed
        bool matchesProximity = true;
        if (_showNearbyOnly && _currentPosition != null) {
          double distance = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            service.latitude,
            service.longitude,
          );
          matchesProximity = distance <= 10.0; // Within 10 km
        }

        return matchesSearch && matchesProximity;
      }).toList();

      // Sort by distance if location is available
      if (_currentPosition != null) {
        _filteredServices.sort((a, b) {
          double distanceA = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          double distanceB = _calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
      }
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ambulance Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.red.shade800,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search ambulance services...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterServices();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Show nearby services only'),
                  subtitle: Text(_currentPosition == null
                      ? 'Enable location to use this feature'
                      : 'Showing services within 10 km'),
                  value: _showNearbyOnly,
                  activeColor: Colors.red.shade800,
                  onChanged: _currentPosition == null
                      ? null
                      : (value) {
                    setState(() {
                      _showNearbyOnly = value;
                      _filterServices();
                    });
                  },
                  dense: true,
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Expanded(
            child: _filteredServices.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ambulance services found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredServices.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                String distance = _currentPosition != null
                    ? '${_calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  service.latitude,
                  service.longitude,
                ).toStringAsFixed(1)} km'
                    : 'Distance unavailable';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: service.available
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                service.available ? 'Available' : 'Busy',
                                style: TextStyle(
                                  color: service.available
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    service.address,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.directions, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  distance,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.rating}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: MediaQuery.of(context).size.width - 64, // Account for padding
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: service.services.map((serviceType) {
                                  return Chip(
                                    label: Text(
                                      serviceType,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.grey.shade100,
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    labelPadding: EdgeInsets.symmetric(horizontal: 4),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey.shade300),
                      InkWell(
                        onTap: () => _makePhoneCall(service.phoneNumber),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: service.available
                                ? Colors.red.shade800
                                : Colors.grey.shade400,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Call Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AmbulanceService {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final List<String> services;
  final bool available;

  AmbulanceService({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.services,
    required this.available,
  });
}