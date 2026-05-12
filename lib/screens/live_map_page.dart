import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isBroadcasting = false;
  Marker? _leaderMarker;

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
    _positionStreamSubscription?.cancel();
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
    setState(() {
      _isBroadcasting = true;
    });

    // Update event document to isLive: true
    await _firestore.collection('events').doc(widget.eventId).update({
      'isLive': true,
    });

    // Start location stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      // Update currentLocation in events document
      final GeoPoint currentLocation = GeoPoint(
        position.latitude,
        position.longitude,
      );

      _firestore.collection('events').doc(widget.eventId).update({
        'currentLocation': currentLocation,
      });
    });
  }

  Future<void> _stopBroadcasting() async {
    setState(() {
      _isBroadcasting = false;
    });

    // Cancel location stream
    _positionStreamSubscription?.cancel();

    // Update event document to isLive: false
    await _firestore.collection('events').doc(widget.eventId).update({
      'isLive': false,
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.7749, -122.4194), // Default to San Francisco
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _leaderMarker != null ? {_leaderMarker!} : {},
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
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }

                final eventData = snapshot.data!.data() as Map<String, dynamic>;
                final bool isLive = eventData['isLive'] as bool? ?? false;
                final GeoPoint? currentLocation = eventData['currentLocation'] as GeoPoint?;

                if (isLive && currentLocation != null) {
                  // Update marker position
                  _leaderMarker = Marker(
                    markerId: MarkerId('leader_${widget.eventId}'),
                    position: LatLng(currentLocation.latitude, currentLocation.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                    infoWindow: InfoWindow(
                      title: 'Group Leader',
                      snippet: widget.eventName,
                    ),
                  );

                  // Center map on leader's position
                  if (_mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(currentLocation.latitude, currentLocation.longitude),
                          zoom: 16,
                        ),
                      ),
                    );
                  }
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
                        color: isLive 
                            ? const Color(0xFF39FF14).withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLive
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
                          isLive ? Icons.live_tv : Icons.location_off,
                          color: isLive 
                              ? const Color(0xFF39FF14)
                              : Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isLive 
                                ? 'Tracking Group Leader Live'
                                : 'Waiting for Leader to Start',
                            style: TextStyle(
                              color: isLive
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
            ),
        ],
      ),
    );
  }
}
