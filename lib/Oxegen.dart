import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class OxygenDetailsScreen extends StatefulWidget {
  const OxygenDetailsScreen({super.key});

  @override
  State<OxygenDetailsScreen> createState() => _OxygenDetailsScreenState();
}

class _OxygenDetailsScreenState extends State<OxygenDetailsScreen> {
  Position? _currentPosition;
  List<OxygenSupplier> _nearbySuppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<OxygenSupplier> _oxygenSuppliersData = [
    OxygenSupplier(name: 'City Oxygen Supplies', latitude: 12.9716, longitude: 77.5946, isAvailable: true),
    OxygenSupplier(name: 'MedPlus Pharmacy - Koramangala', latitude: 12.9352, longitude: 77.6245, isAvailable: true),
    OxygenSupplier(name: 'Global Healthcare Oxygen', latitude: 13.0203, longitude: 77.5699, isAvailable: false),
    OxygenSupplier(name: 'Sai Oxygen Agency', latitude: 12.9000, longitude: 77.7000, isAvailable: true),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nearbySuppliers.clear();
    });

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location services are disabled. Please enable them.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission denied. Enable to continue.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Location permission permanently denied. Open settings.';
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      await _findNearbyOxygenSuppliers();
    } catch (e) {
      _errorMessage = 'Error fetching location: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _findNearbyOxygenSuppliers() async {
    if (_currentPosition == null) return;

    List<OxygenSupplier> nearby = [];
    for (final supplier in _oxygenSuppliersData) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        supplier.latitude,
        supplier.longitude,
      );

      if (distance <= 1000000) {
        nearby.add(supplier.copyWith(distance: distance));
      }
    }

    nearby.sort((a, b) => a.distance!.compareTo(b.distance!));
    setState(() {
      _nearbySuppliers = nearby;
    });
  }

  String _formatDistance(double? distance) {
    if (distance == null) return 'Unknown';
    return distance < 1000
        ? '${distance.toStringAsFixed(0)} meters'
        : '${(distance / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Oxygen Suppliers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _nearbySuppliers.isEmpty
          ? const Center(child: Text('No nearby suppliers found.'))
          : ListView.builder(
        itemCount: _nearbySuppliers.length,
        itemBuilder: (context, index) {
          final supplier = _nearbySuppliers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Distance: ${_formatDistance(supplier.distance)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Availability: ${supplier.isAvailable ? 'Available' : 'Not Available'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: supplier.isAvailable
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(supplier.latitude, supplier.longitude),
                      icon: const Icon(Icons.map),
                      label: const Text('View on Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OxygenSupplier {
  final String name;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final double? distance;

  OxygenSupplier({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    this.distance,
  });

  OxygenSupplier copyWith({double? distance}) {
    return OxygenSupplier(
      name: name,
      latitude: latitude,
      longitude: longitude,
      isAvailable: isAvailable,
      distance: distance ?? this.distance,
    );
  }
}
