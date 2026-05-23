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
  LatLng? currentLocation;

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    if (_isBroadcasting) {
      _stopBroadcasting();
    }
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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

    // Check if event is ongoing
    final eventDoc = await _firestore.collection('events').doc(widget.eventId).get();
    if (!eventDoc.exists) return;
    final eventData = eventDoc.data()!;
    final eventDate = (eventData['date'] as Timestamp).toDate();
    final isOngoing = DateTime.now().isAfter(eventDate) || DateTime.now().isAtSameMomentAs(eventDate);
    
    if (!isOngoing) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
           content: Text('Cannot broadcast: Event is not ongoing yet.'),
           backgroundColor: Colors.red,
         ));
       }
       return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission required'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    setState(() {
      _isBroadcasting = true;
    });

    final collectionName = widget.isGroupLeader ? 'group_leader' : 'user';
    await _firestore.collection(collectionName).doc(user.uid).update({'isBroadcasting': true});

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
      mapController.move(currentLocation!, 15.0);
      _firestore.collection(collectionName).doc(user.uid).update({
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

    positionStream?.cancel();
    final collectionName = widget.isGroupLeader ? 'group_leader' : 'user';
    await _firestore.collection(collectionName).doc(user.uid).update({'isBroadcasting': false});
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // MAP DISPLAY
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('events').doc(widget.eventId).snapshots(),
            builder: (context, eventSnapshot) {
              final String? creatorId = eventSnapshot.data?.get('creatorId');

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('participation').where('eventId', isEqualTo: widget.eventId).snapshots(),
                builder: (context, participationSnapshot) {
                  final participantIds = participationSnapshot.data?.docs.map((d) => d['userId']).toList() ?? [];

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('user').snapshots(),
                    builder: (context, usersSnapshot) {
                      final participatingUsers = usersSnapshot.data?.docs.where((u) => participantIds.contains(u.id)).toList() ?? [];

                      return StreamBuilder<DocumentSnapshot>(
                        stream: creatorId != null ? _firestore.collection('group_leader').doc(creatorId).snapshots() : const Stream.empty(),
                        builder: (context, leaderSnapshot) {
                          List<Marker> markers = [];

                          // Add User Markers (Blue)
                          for (var userDoc in participatingUsers) {
                            final userData = userDoc.data() as Map<String, dynamic>;
                            if (userData['isBroadcasting'] == true && userData['latitude'] != null && userData['longitude'] != null) {
                              markers.add(
                                Marker(
                                  point: LatLng(userData['latitude'], userData['longitude']),
                                  width: 30,
                                  height: 30,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                                  ),
                                ),
                              );
                            }
                          }

                          // Add Group Leader Marker (Red)
                          if (leaderSnapshot.hasData && leaderSnapshot.data!.exists) {
                            final leaderData = leaderSnapshot.data!.data() as Map<String, dynamic>;
                            if (leaderData['isBroadcasting'] == true && leaderData['latitude'] != null && leaderData['longitude'] != null) {
                              markers.add(
                                Marker(
                                  point: LatLng(leaderData['latitude'], leaderData['longitude']),
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.star, color: Colors.white, size: 20),
                                  ),
                                ),
                              );
                            }
                          }

                          return FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(36.9060, 7.7615),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.hubike',
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),

          // BROADCASTING CONTROLS (For both Leader and Participants)
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
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isBroadcasting ? Icons.live_tv : Icons.location_off,
                        color: _isBroadcasting ? const Color(0xFF39FF14) : Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isBroadcasting ? 'Broadcasting Live Location' : 'Location Sharing Off',
                          style: TextStyle(
                            color: _isBroadcasting ? const Color(0xFF39FF14) : Colors.white.withOpacity(0.6),
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
                            color: _isBroadcasting ? Colors.white : Colors.white.withOpacity(0.6),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
