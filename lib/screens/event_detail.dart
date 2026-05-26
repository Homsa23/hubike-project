import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_model.dart';
import 'ticket_page.dart';

class EventDetailPage extends StatelessWidget {
  final HubikeEvent event;
  final Map<String, dynamic>? currentUser;

  const EventDetailPage({super.key, required this.event, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            bottom: 120, // Leave space for bottom button
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO IMAGE
                Stack(
                  children: [
                    Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage('assets/adventure.jpg'),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF050505).withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: 50,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212).withAlpha(180),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Capacity badge (top right)
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withAlpha(30),
                          border: Border.all(color: const Color(0xFF39FF14).withAlpha(100)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'CAPACITY: ${event.capacity}',
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    // Title on image
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Text(
                        event.eventName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          height: 0.9,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // STATS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatCard('DATE', _formatFullDateTime(event.date), Icons.calendar_today),
                      const SizedBox(width: 10),
                      _buildStatCard('LEVEL', event.level.toUpperCase(), Icons.fitness_center),
                      const SizedBox(width: 10),
                      _buildStatCard('COINS', '+${event.coinsToEarn}', Icons.monetization_on),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // HOST CARD (Simplified)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withAlpha(30),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF39FF14)),
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF39FF14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HOSTED BY',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.creatorName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // DESCRIPTION
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ABOUT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // LOCATION CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF39FF14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.startingPoint.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Starting Point',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // OFFICIAL EVENT LINK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () async {
                      if (event.officialPageLink.isNotEmpty) {
                        final url = Uri.parse(event.officialPageLink);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.link,
                          color: Color(0xFF39FF14),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          event.officialPageLink.isNotEmpty
                              ? 'Official Event Page'
                              : 'No Official Link',
                          style: TextStyle(
                            color: const Color(0xFF39FF14),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF39FF14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 140), // Extra space to scroll past fixed bottom button
              ],
            ),
          ),
        ),

          // BOTTOM JOIN BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050505).withAlpha(240),
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(10)),
                ),
              ),
              child: Column(
                children: [
                  // Price display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${event.price} DZD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Real-time participation check
                  StreamBuilder<QuerySnapshot>(
                    stream: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return null;
                      return FirebaseFirestore.instanceFor(
                        app: Firebase.app(),
                        databaseId: 'default',
                      )
                          .collection('participation')
                          .where('eventId', isEqualTo: event.id)
                          .where('userId', isEqualTo: user.uid)
                          .snapshots();
                    }(),
                    builder: (context, snapshot) {
                      final user = FirebaseAuth.instance.currentUser;

                      // Not logged in - show join button that prompts login
                      if (user == null) {
                        return _buildJoinButton(context, isLoggedIn: false);
                      }

                      final isParticipating = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                      if (isParticipating) {
                        // Get the actual participation document ID from Firestore
                        final participationDoc = snapshot.data!.docs.first;
                        final participationId = participationDoc.id;
                        // Already joined - show View My Ticket button
                        return _buildViewTicketButton(context, participationId);
                      } else {
                        // Calculate availability
                        bool isOngoing = DateTime.now().isAfter(event.date) || DateTime.now().isAtSameMomentAs(event.date);
                        bool isFull = event.currentParticipants >= event.capacity;
                        bool isTooLate = DateTime.now().isAfter(event.date.subtract(const Duration(hours: 1)));
                        
                        if (isOngoing) {
                          return _buildDisabledJoinButton('EVENT ONGOING');
                        } else if (isFull) {
                          return _buildDisabledJoinButton('EVENT FULL');
                        } else if (isTooLate || event.status != 'Available') {
                          return _buildDisabledJoinButton('UNAVAILABLE');
                        }

                        // Not joined - show Join button
                        return _buildJoinButton(context, isLoggedIn: true, event: event);
                      }
                    },
                  ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildJoinButton(BuildContext context, {required bool isLoggedIn, HubikeEvent? event}) {
    return ElevatedButton(
      onPressed: () async {
        if (!isLoggedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to join this event'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        try {
          final firestore = FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'default',
          );

          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          final existingParticipation = await firestore
              .collection('participation')
              .where('eventId', isEqualTo: event!.id)
              .where('userId', isEqualTo: user.uid)
              .get();

          if (existingParticipation.docs.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already generated a ticket for this event!'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          final participationId = '${user.uid}_${event.id}';
          final participationRef = firestore.collection('participation').doc(participationId);

          await participationRef.set({
            'id': participationId,
            'userId': user.uid,
            'eventId': event.id,
            'registrationDate': FieldValue.serverTimestamp(),
            'ispresent': false,
            'joinedbycoins': false,
            'winnedCoins': 0,
            'status': 'Registered',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined event!'),
              backgroundColor: Color(0xFF39FF14),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketPage(
                event: event,
                participationId: participationId,
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error joining event: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, size: 24),
          SizedBox(width: 8),
          Text(
            'JOIN RIDE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTicketButton(BuildContext context, String participationId) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketPage(
              event: event,
              participationId: participationId,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code, size: 24),
          SizedBox(width: 8),
          Text(
            'VIEW MY TICKET',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  
// Simple stat card widget
Widget _buildStatCard(String label, String value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDisabledJoinButton(String reason) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.withOpacity(0.3),
        foregroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 24),
          const SizedBox(width: 8),
          Text(
            reason,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
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
