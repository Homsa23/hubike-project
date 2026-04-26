import 'package:flutter/material.dart';
import 'event_model.dart';
import 'join_event.dart';

class EventDetailPage extends StatelessWidget {
  final HubikeEvent event;
  final Map<String, dynamic>? currentUser;

  const EventDetailPage({super.key, required this.event, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Event Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.eventName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(event.date, style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 20),
                const Icon(Icons.location_on, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                Text(event.startingPoint, style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              event.description,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFF39FF14)),
                const SizedBox(width: 8),
                Text(
                  '+${event.coinsToEarn} Coins',
                  style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JoinEventPage(event: event, currentUser: currentUser),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'JOIN',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
