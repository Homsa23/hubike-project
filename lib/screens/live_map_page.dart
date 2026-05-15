import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveMapPage extends StatefulWidget {
  final String eventId;
  final String eventName;
  final bool isGroupLeader;

  const LiveMapPage({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.isGroupLeader,
  });

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final MapController mapController = MapController();
  StreamSubscription<Position>? positionStream;
  bool _isBroadcasting = false;
  LatLng? _leaderPosition;
  LatLng? currentLocation;

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  @override
  void initState() {
    super.initState();
    if (widget.isGroupLeader) {
      _initializeLeaderMode();
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    if (widget.isGroupLeader && _isBroadcasting) {
      _stopBroadcasting();
    }
    super.dispose();
  }

  Future<void> _initializeLeaderMode() async {
    // Request location permissions
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return;
    }
  }

  Future<void> _toggleBroadcasting(bool value) async {
    if (value) {
      await _startBroadcasting();
    } else {
      await _stopBroadcasting();
    }
  }

  Future<void> _startBroadcasting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Bulletproof permission checking
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isBroadcasting = true;
    });

    // Update group_leader document with isBroadcasting: true
    await _firestore.collection('group_leader').doc(user.uid).update({
      'isBroadcasting': true,
    });

    // Delivery-app style location stream
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      // 1. Update Map UI
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        _leaderPosition = currentLocation;
      });
      // 2. Move Camera
      mapController.move(currentLocation!, 15.0);
      // 3. Update Firestore
      FirebaseFirestore.instance.collection('group_leader').doc(user.uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'isBroadcasting': true,
      });
    });
  }

  Future<void> _stopBroadcasting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isBroadcasting = false;
    });

    // Cancel location stream
    positionStream?.cancel();

    // Update group_leader document with isBroadcasting: false
    await _firestore.collection('group_leader').doc(user.uid).update({
      'isBroadcasting': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          widget.eventName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // FlutterMap with OpenStreetMap tiles
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(36.9060, 7.7615), // Default to Annaba, Algeria
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hubike',
              ),
              if (_leaderPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _leaderPosition!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF39FF14).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bike,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Group Leader Broadcasting Controls
          if (widget.isGroupLeader)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isBroadcasting 
                        ? const Color(0xFF39FF14).withOpacity(0.5)
                        : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isBroadcasting
                          ? const Color(0xFF39FF14).withOpacity(0.2)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isBroadcasting ? Icons.live_tv : Icons.location_off,
                          color: _isBroadcasting 
                              ? const Color(0xFF39FF14)
                              : Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isBroadcasting 
                                ? 'Broadcasting Live Location'
                                : 'Location Sharing Off',
                            style: TextStyle(
                              color: _isBroadcasting
                                  ? const Color(0xFF39FF14)
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'START BROADCASTING',
                            style: TextStyle(
                              color: _isBroadcasting
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isBroadcasting,
                          onChanged: _toggleBroadcasting,
                          activeColor: const Color(0xFF39FF14),
                          activeTrackColor: const Color(0xFF39FF14).withOpacity(0.3),
                          inactiveThumbColor: Colors.white.withOpacity(0.6),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Rider View - Live Location Tracking
          if (!widget.isGroupLeader)
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
              builder: (context, eventSnapshot) {
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
                final String? creatorId = eventData['creatorId'] as String?;

                if (creatorId == null) {
                  return const SizedBox.shrink();
                }

                // Listen to group_leader document
                return StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('group_leader').doc(creatorId).snapshots(),
                  builder: (context, leaderSnapshot) {
                    if (!leaderSnapshot.hasData || !leaderSnapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final leaderData = leaderSnapshot.data!.data() as Map<String, dynamic>;
                    final bool isBroadcasting = leaderData['isBroadcasting'] as bool? ?? false;
                    final double? latitude = leaderData['latitude'] as double?;
                    final double? longitude = leaderData['longitude'] as double?;

                    if (isBroadcasting && latitude != null && longitude != null) {
                      // Update leader position
                      setState(() {
                        _leaderPosition = LatLng(latitude, longitude);
                      });

                      // Center map on leader's position
                      mapController.move(_leaderPosition!, 16);
                    }

                    return Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isBroadcasting
                                ? const Color(0xFF39FF14).withOpacity(0.5)
                                : Colors.white.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isBroadcasting
                                  ? const Color(0xFF39FF14).withOpacity(0.2)
                                  : Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBroadcasting ? Icons.live_tv : Icons.location_off,
                              color: isBroadcasting
                                  ? const Color(0xFF39FF14)
                                  : Colors.white.withOpacity(0.6),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isBroadcasting
                                    ? 'Tracking Group Leader Live'
                                    : 'Waiting for Leader to Start',
                                style: TextStyle(
                                  color: isBroadcasting
                                      ? const Color(0xFF39FF14)
                                      : Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
