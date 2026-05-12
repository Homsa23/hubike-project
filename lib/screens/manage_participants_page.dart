import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ManageParticipantsPage extends StatelessWidget {
  final String eventId;
  final String eventName;

  const ManageParticipantsPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Text(
              'Participants',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        shape: const Border(
          bottom: BorderSide(color: Colors.white24, width: 0.2),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('participation')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39FF14),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading participants: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final participants = snapshot.data?.docs ?? [];

          if (participants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No riders have joined this event yet.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participation = participants[index].data() as Map<String, dynamic>;
              final userId = participation['userId'] as String?;
              final isPresent = participation['ispresent'] as bool? ?? false;

              if (userId == null) {
                return _buildErrorCard('Invalid participant data');
              }

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('user').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return _buildParticipantCard(
                      name: 'Unknown Rider',
                      isPresent: isPresent,
                      isLoading: false,
                    );
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final firstName = userData?['first_name'] ?? 'Unknown';
                  final lastName = userData?['last_name'] ?? 'Rider';

                  return _buildParticipantCard(
                    name: '$firstName $lastName',
                    isPresent: isPresent,
                    isLoading: false,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyan.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.cyan,
          ),
        ),
        title: Text(
          'Loading rider...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 24,
        ),
        title: Text(
          message,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCard({
    required String name,
    required bool isPresent,
    required bool isLoading,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent 
              ? const Color(0xFF39FF14).withOpacity(0.5) 
              : Colors.grey.withOpacity(0.3),
          width: isPresent ? 2 : 1,
        ),
        boxShadow: isPresent
            ? [
                BoxShadow(
                  color: const Color(0xFF39FF14).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPresent 
                ? const Color(0xFF39FF14).withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPresent 
                  ? const Color(0xFF39FF14).withOpacity(0.5) 
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.person,
            color: isPresent ? const Color(0xFF39FF14) : Colors.grey,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isPresent ? 'Present (Ticket Scanned)' : 'Waiting for scan...',
          style: TextStyle(
            color: isPresent 
                ? const Color(0xFF39FF14) 
                : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          isPresent ? Icons.check_circle : Icons.access_time,
          color: isPresent ? const Color(0xFF39FF14) : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
