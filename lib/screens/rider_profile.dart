import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'edit_profile_screen.dart';

class RiderProfilePage extends StatefulWidget {
  const RiderProfilePage({Key? key}) : super(key: key);

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  Future<Map<String, dynamic>> _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
    final userDoc = await firestore.collection('user').doc(uid).get();

    final userData = (userDoc.data() as Map<String, dynamic>?) ?? {};

    return {
      'first_name': userData['first_name'] ?? '',
      'last_name': userData['last_name'] ?? '',
      'email': userData['email'] ?? '',
      'phone_number': userData['phone_number'] ?? '',
      'residence': userData['residence'] ?? '',
      'coins': (userData['coins'] ?? 0),
      'image': userData['image'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Core dark theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MY PROFILE',
          style: TextStyle(
            color: Color(0xFF39FF14), // Neon green accent
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF39FF14)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading profile:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final image = (data['image']?.toString()) ?? '';
          final firstName = (data['first_name']?.toString()) ?? '';
          final lastName = (data['last_name']?.toString()) ?? '';
          
          // Safely handle coins whether it's an int, double, or string in Firestore
          int coins = 0;
          if (data['coins'] is num) {
            coins = (data['coins'] as num).toInt();
          } else if (data['coins'] is String) {
            coins = int.tryParse(data['coins']) ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // -----------------------------------------------------
                // HERO SECTION
                // -----------------------------------------------------
                _buildAvatar(image),
                const SizedBox(height: 16),
                
                // Name
                Text(
                  '${firstName.toUpperCase()} ${lastName.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),

                // -----------------------------------------------------
                // WALLET SECTION
                // -----------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF39FF14).withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39FF14).withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL BALANCE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Color(0xFF39FF14),
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$coins',
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // -----------------------------------------------------
                // INFO CARDS
                // -----------------------------------------------------
                _buildInfoCard(
                  icon: Icons.email_outlined,
                  title: 'EMAIL',
                  value: (data['email']?.toString()) ?? '',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.phone_android,
                  title: 'PHONE NUMBER',
                  value: (data['phone_number']?.toString()) ?? '',
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  title: 'RESIDENCE',
                  value: (data['residence']?.toString()) ?? '',
                ),
                
                const SizedBox(height: 60), 

                // -----------------------------------------------------
                // ACTION SECTION
                // -----------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Navigate to edit profile screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(userData: data),
                        ),
                      );
                      if (result == true) {
                        // Force a refresh if profile was updated
                        setState(() {});
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF39FF14),
                      side: const BorderSide(color: Color(0xFF39FF14), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'MODIFY PROFILE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16), 

                // -----------------------------------------------------
                // ACTION SECTION (SIGN OUT)
                // -----------------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    // Pass true back to the home.dart to let it know the user clicked Sign Out
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'SIGN OUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  // Graceful fallback for the avatar image
  Widget _buildAvatar(String imageUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E1E1E),
        border: Border.all(
          color: const Color(0xFF39FF14),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39FF14).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.trim().isEmpty
            ? Icon(
                Icons.person,
                size: 60,
                color: const Color(0xFF39FF14).withOpacity(0.8),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  size: 60,
                  color: const Color(0xFF39FF14).withOpacity(0.8),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.cyanAccent,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : 'Not provided',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
