import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'event_model.dart';
import 'live_map_page.dart';

class TicketPage extends StatefulWidget {
  final HubikeEvent event;
  final String participationId;

  const TicketPage({
    super.key,
    required this.event,
    required this.participationId,
  });

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final eventDate = widget.event.date;
    final now = DateTime.now();
    final remaining = eventDate.difference(now);
    if (mounted) {
      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  Future<void> _openMaps() async {
    final location = widget.event.startingPoint;
    if (location.isEmpty || location == 'TBD') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting point not available')),
      );
      return;
    }

    final encodedLocation = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
    
    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.event.eventName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Event Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF39FF14).withOpacity(0.1),
                    const Color(0xFF39FF14).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Countdown Timer
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeUnit(days, 'DAYS'),
                          const SizedBox(width: 8),
                          Text(
                            ':',
                            style: TextStyle(
                              color: const Color(0xFF39FF14).withOpacity(0.7),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTimeUnit(hours, 'HOURS'),
                          const SizedBox(width: 8),
                          Text(
                            ':',
                            style: TextStyle(
                              color: const Color(0xFF39FF14).withOpacity(0.7),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTimeUnit(minutes, 'MINS'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Event Date: ${_formatFullDateTime(widget.event.date)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Starting Point: ${widget.event.startingPoint}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gamification Hook
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14).withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF39FF14).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFF39FF14),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Validate presence to unlock ${widget.event.coinsToEarn} Hubike Coins!',
                      style: const TextStyle(
                        color: Color(0xFF39FF14),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // QR Code Section with Live Tracking
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'default',
              ).collection('events').doc(widget.event.id).snapshots(),
              builder: (context, eventSnapshot) {
                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39FF14).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.participationId,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.participationId.substring(0, widget.participationId.length > 8 ? 8 : widget.participationId.length).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Show this to the Group Leader at the starting line to validate your presence.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final eventData = eventSnapshot.data!.data() as Map<String, dynamic>;
                final String? creatorId = eventData['creatorId'] as String?;

                if (creatorId == null) {
                  return Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF39FF14).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: widget.participationId,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050505),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.participationId.substring(0, widget.participationId.length > 8 ? 8 : widget.participationId.length).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Show this to the Group Leader at the starting line to validate your presence.',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Listen to group_leader document for isBroadcasting
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instanceFor(
                    app: Firebase.app(),
                    databaseId: 'default',
                  ).collection('group_leader').doc(creatorId).snapshots(),
                  builder: (context, leaderSnapshot) {
                    final bool isBroadcasting = leaderSnapshot.hasData &&
                        leaderSnapshot.data!.exists &&
                        ((leaderSnapshot.data!.data() as Map<String, dynamic>)['isBroadcasting'] as bool? ?? false);

                    return Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: widget.participationId,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF050505),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.participationId.substring(0, widget.participationId.length > 8 ? 8 : widget.participationId.length).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF39FF14),
                                fontSize: 12,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Show this to the Group Leader at the starting line to validate your presence.',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // Live Tracking Button (only show when leader is broadcasting)
                          if (isBroadcasting) ...[
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LiveMapPage(
                                        eventId: widget.event.id,
                                        eventName: widget.event.eventName,
                                        isGroupLeader: false,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.location_on, size: 20),
                                label: const Text('TRACK LIVE RIDE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF39FF14),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Navigate Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF39FF14),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.startingPoint,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.navigation, color: Colors.black),
                    label: const Text(
                      'Navigate to Start',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF39FF14).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xFF39FF14),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatFullDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString();
    final yearStr = date.year.toString();
    final hourStr = date.hour.toString().padLeft(2, '0');
    final minuteStr = date.minute.toString().padLeft(2, '0');
    return '$monthStr $dayStr, $yearStr - $hourStr:$minuteStr';
  }
}
