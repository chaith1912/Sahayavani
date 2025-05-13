import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart'; // Added for location services
import 'package:geocoding/geocoding.dart'; // Added for geocoding addresses

class BloodBankListScreen extends StatefulWidget {
  const BloodBankListScreen({super.key});

  @override
  _BloodBankListScreenState createState() => _BloodBankListScreenState();
}

class _BloodBankListScreenState extends State<BloodBankListScreen> {
  List<Map<String, dynamic>> _bloodBanks = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedState = 'All States';
  List<String> _states = ['All States'];
  Map<String, dynamic>? _selectedBloodBank;
  bool _showBloodGroups = false;
  Position? _currentPosition; // Store user's current position
  String _currentStateFromLocation = ''; // Store user's current state based on location
  bool _isLoadingLocation = false; // Loading state for location fetching

  // Sample blood group availability data (in a real app, this would come from API)
  final Map<String, Map<String, String>> _bloodGroupAvailability = {
    "Delhi": {
      "A+": "Available",
      "B+": "Low Stock",
      "O+": "Available",
      "AB+": "Not Available",
      "A-": "Available",
      "B-": "Not Available",
      "O-": "Low Stock",
      "AB-": "Not Available",
    },
    "Maharashtra": {
      "A+": "Available",
      "B+": "Available",
      "O+": "Low Stock",
      "AB+": "Available",
      "A-": "Not Available",
      "B-": "Available",
      "O-": "Not Available",
      "AB-": "Low Stock",
    },
    // Add more states as needed
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Get location when screen initializes
    _fetchBloodBankData();
  }

  // Method to get the current user location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
      });

      // Convert position to address to get state
      await _getAddressFromLatLng();

    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Get address details from latitude and longitude
  Future<void> _getAddressFromLatLng() async {
    try {
      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String stateName = place.administrativeArea ?? '';

          // If we found a state, update the selected state
          if (stateName.isNotEmpty && _states.contains(stateName)) {
            setState(() {
              _currentStateFromLocation = stateName;
              _selectedState = stateName;
            });
          }
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  Future<void> _fetchBloodBankData() async {
    const url =
        'https://api.data.gov.in/resource/f69c02f6-aceb-466f-9546-8e18f30abea9?api-key=579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b&format=json&limit=100&offset=0';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['records'] != null) {
          _bloodBanks = List<Map<String, dynamic>>.from(
            data['records'].map((record) {
              // Enhanced to include mock coordinates for each blood bank
              return {
                'state___ut': record['state___ut']?.toString() ?? 'N/A',
                'govt__blood_centres':
                record['govt__blood_centres']?.toString() ?? 'N/A',
                'other_than_govt__blood_centres':
                record['other_than_govt__blood_centres']?.toString() ??
                    'N/A',
                '_total': record['_total']?.toString() ?? 'N/A',
                'contact': '1800-123-4567', // Sample contact number
                'address':
                'Sample Address, ${record['state___ut']?.toString() ?? ''}', // Sample address
                'latitude': _getRandomLatitude(record['state___ut']?.toString() ?? ''),
                'longitude': _getRandomLongitude(record['state___ut']?.toString() ?? ''),
                'distance': 0.0, // Will be calculated later if location available
              };
            }),
          );

          _states = [
            'All States',
            ..._bloodBanks.map((bank) => bank['state___ut'] as String).toSet(),
          ];
          _states.sort();

          // If we already have the user's location, calculate distances
          if (_currentPosition != null) {
            _calculateDistances();
          }

          // Check if current state from location exists in our states list
          if (_currentStateFromLocation.isNotEmpty && _states.contains(_currentStateFromLocation)) {
            setState(() {
              _selectedState = _currentStateFromLocation;
            });
          }
        } else {
          _error = 'No blood bank data found.';
        }
      } else {
        _error = 'Failed to fetch data. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mock function to get latitude based on state name (in a real app, use real coordinates)
  double _getRandomLatitude(String state) {
    // These are approximate center points for some Indian states
    final Map<String, double> stateLatitudes = {
      'Delhi': 28.7041,
      'Maharashtra': 19.7515,
      'Tamil Nadu': 11.1271,
      'Karnataka': 15.3173,
      'Gujarat': 22.2587,
      'West Bengal': 22.9868,
      'Uttar Pradesh': 26.8467,
    };

    // Return known latitude or a random one within India
    return stateLatitudes[state] ?? (20.5937 + (DateTime.now().millisecond % 10) / 10);
  }

  // Mock function to get longitude based on state name (in a real app, use real coordinates)
  double _getRandomLongitude(String state) {
    // These are approximate center points for some Indian states
    final Map<String, double> stateLongitudes = {
      'Delhi': 77.1025,
      'Maharashtra': 75.7139,
      'Tamil Nadu': 78.6569,
      'Karnataka': 75.7139,
      'Gujarat': 71.1924,
      'West Bengal': 87.8550,
      'Uttar Pradesh': 80.9462,
    };

    // Return known longitude or a random one within India
    return stateLongitudes[state] ?? (78.9629 + (DateTime.now().millisecond % 10) / 10);
  }

  // Calculate distances between current user location and all blood banks
  void _calculateDistances() {
    if (_currentPosition == null) return;

    for (var bank in _bloodBanks) {
      double bankLat = bank['latitude'];
      double bankLng = bank['longitude'];

      // Calculate distance in kilometers
      double distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          bankLat,
          bankLng
      );

      bank['distance'] = distanceInMeters / 1000; // Convert to kilometers
    }

    // Sort blood banks by distance
    _bloodBanks.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
  }

  List<Map<String, dynamic>> get filteredBloodBanks {
    if (_selectedState == 'All States') {
      return _bloodBanks;
    } else {
      return _bloodBanks
          .where((bank) => bank['state___ut'] == _selectedState)
          .toList();
    }
  }

  void _showBloodBankDetails(Map<String, dynamic> bloodBank) {
    setState(() {
      _selectedBloodBank = bloodBank;
      _showBloodGroups = true;
    });
  }

  void _hideBloodBankDetails() {
    setState(() {
      _showBloodGroups = false;
      _selectedBloodBank = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Banks'),
        elevation: 0,
        backgroundColor: Color(0xFFE53935), // Red theme for blood banks
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Added location refresh button
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocation();
              if (_currentPosition != null) {
                _calculateDistances();
                setState(() {}); // Refresh UI
              }
            },
          ),
        ],
      ),
      body:
      _isLoading
          ? Center(
        child: CircularProgressIndicator(color: Color(0xFFE53935)),
      )
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error,
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = '';
                });
                _getCurrentLocation();
                _fetchBloodBankData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _bloodBanks.isEmpty
          ? Center(
        child: Text(
          'No blood banks available.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Stack(
        children: [
          Column(
            children: [
              // Location status indicator
              if (_isLoadingLocation)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Getting your location...',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),

              // Current location indicator
              if (_currentPosition != null && !_isLoadingLocation)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  color: Colors.green.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Using your current location in ${_currentStateFromLocation.isEmpty ? "India" : _currentStateFromLocation}',
                          style: TextStyle(color: Colors.green),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // State filter dropdown with improved design
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFE53935),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Filter by State:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedState,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down),
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 16,
                            ),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedState = newValue!;
                              });
                            },
                            items:
                            _states.map<DropdownMenuItem<String>>((
                                String value,
                                ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary cards with better layout
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total States',
                        value: (_states.length - 1).toString(),
                        icon: Icons.map,
                        color: Color(0xFF4285F4), // Blue
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        title: 'Total Centers',
                        value:
                        _bloodBanks
                            .map(
                              (bank) =>
                          int.tryParse(
                            bank['_total'] ?? '0',
                          ) ??
                              0,
                        )
                            .reduce((a, b) => a + b)
                            .toString(),
                        icon: Icons.local_hospital,
                        color: Color(0xFFE53935), // Red
                      ),
                    ),
                  ],
                ),
              ),

              // Blood banks list with improved card design
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBloodBanks.length,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemBuilder: (context, index) {
                    final bank = filteredBloodBanks[index];
                    return GestureDetector(
                      onTap: () => _showBloodBankDetails(bank),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Color(0xFFE53935),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      bank['state___ut'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                  // Distance indicator if location is available
                                  if (_currentPosition != null && bank['distance'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.directions, size: 14, color: Colors.blue),
                                          SizedBox(width: 4),
                                          Text(
                                            '${bank['distance'].toStringAsFixed(1)} km',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10),
                              _buildInfoRow(
                                icon: Icons.phone,
                                text:
                                bank['contact'] ??
                                    'Contact not available',
                                color: Colors.green,
                              ),
                              SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.home_work,
                                text:
                                '${bank['govt__blood_centres'] ?? 'N/A'} Govt. Centers',
                                color: Colors.blue,
                              ),
                              SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.business,
                                text:
                                '${bank['other_than_govt__blood_centres'] ?? 'N/A'} Private Centers',
                                color: Colors.orange,
                              ),
                              SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.add_location_alt,
                                text:
                                bank['address'] ??
                                    'Address not available',
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      0xFFE53935,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ),
                                  ),
                                  child: Text(
                                    'View Blood Groups',
                                    style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Blood group availability overlay
          if (_showBloodGroups && _selectedBloodBank != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Blood Group Availability',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: _hideBloodBankDetails,
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            _selectedBloodBank!['state___ut'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Distance info in popup
                          if (_currentPosition != null && _selectedBloodBank!['distance'] != null)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.directions, size: 16, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Distance: ${_selectedBloodBank!['distance'].toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio:
                            2.5, // Adjusted childAspectRatio to make cards wider
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: [
                              _buildBloodGroupCard('A+'),
                              _buildBloodGroupCard('B+'),
                              _buildBloodGroupCard('O+'),
                              _buildBloodGroupCard('AB+'),
                              _buildBloodGroupCard('A-'),
                              _buildBloodGroupCard('B-'),
                              _buildBloodGroupCard('O-'),
                              _buildBloodGroupCard('AB-'),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Use coordinates for more accurate mapping if available
                                    if (_selectedBloodBank!['latitude'] != null &&
                                        _selectedBloodBank!['longitude'] != null) {
                                      _launchMapWithCoordinates(
                                          _selectedBloodBank!['latitude'],
                                          _selectedBloodBank!['longitude'],
                                          _selectedBloodBank!['address'] ?? '',
                                          context,
                                      );
                                    } else {
                                      _launchMap(
                                        _selectedBloodBank!['address'] ?? '',
                                        _selectedBloodBank!['latitude'],
                                        _selectedBloodBank!['longitude'],
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.map),
                                  label: Text('View on Map'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _makePhoneCall(
                                      _selectedBloodBank!['contact'] ??
                                          '',
                                    );
                                  },
                                  icon: Icon(Icons.call),
                                  label: Text('Call Center'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_currentPosition != null)
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _launchDirections(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                    _selectedBloodBank!['latitude'],
                                    _selectedBloodBank!['longitude'],
                                  );
                                },
                                icon: Icon(Icons.directions),
                                label: Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodGroupCard(String bloodGroup) {
    final state = _selectedBloodBank?['state___ut'] ?? '';
    final availability =
        _bloodGroupAvailability[state]?[bloodGroup] ?? 'Unknown';

    Color statusColor;
    switch (availability) {
      case 'Available':
        statusColor = Colors.green;
        break;
      case 'Low Stock':
        statusColor = Colors.orange;
        break;
      case 'Not Available':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                bloodGroup,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Flexible(
                  // Use Flexible here
                  child: Text(
                    availability,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                    softWrap: true, // Ensure text wraps
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _launchMap(String address,double latitude,double longitude) async {
    final encodedName = Uri.encodeComponent(address);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude ';


    final Uri googleUri = Uri.parse(googleUrl);


    try{
      await launchUrl(googleUri);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch maps.')),
      );
    }
  }

}

  // Launch map with coordinates for more accuracy
  Future<void> _launchMapWithCoordinates(double latitude, double longitude, String name,BuildContext context) async {
    final encodedName = Uri.encodeComponent(name);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude ($encodedName)';


    final Uri googleUri = Uri.parse(googleUrl);


    try{
      await launchUrl(googleUri);
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch maps.')),
      );
    }
  }

  // Launch Google Maps directions from current location to blood bank
  Future<void> _launchDirections(
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      ) async {
    String directionsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(directionsUrl))) {
      await launchUrl(Uri.parse(directionsUrl));
    } else {
      throw 'Could not launch directions';
    }
  }
