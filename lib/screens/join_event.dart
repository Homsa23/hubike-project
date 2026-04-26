import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'event_model.dart';

class JoinEventPage extends StatefulWidget {
  final HubikeEvent event;
  final Map<String, dynamic>? currentUser;

  const JoinEventPage({super.key, required this.event, this.currentUser});

  @override
  State<JoinEventPage> createState() => _JoinEventPageState();
}

class _JoinEventPageState extends State<JoinEventPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.currentUser?['first_name'] ?? '';
    surnameController.text = widget.currentUser?['last_name'] ?? '';
    phoneController.text = widget.currentUser?['phone_number'] ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF39FF14)),
    );
  }

  Future<void> _joinEvent() async {
    if (nameController.text.trim().isEmpty || surnameController.text.trim().isEmpty) {
      _showError('Please enter both name and surname.');
      return;
    }
    if (phoneController.text.trim().length != 10) {
      _showError('Please enter a valid 10-digit phone number.');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final participationRef = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      ).collection('participation').doc();

      await participationRef.set({
        'id': participationRef.id,
        'eventId': widget.event.id,
        'name': nameController.text.trim(),
        'surname': surnameController.text.trim(),
        'phone_number': phoneController.text.trim(),
        'joinedbycoins': widget.event.coinsToEarn,
        'registrationdate': FieldValue.serverTimestamp(),
        'ispresent': false,
        'status': 'registered',
        'joinedby': widget.currentUser?['phone_number'] ?? '',
      });

      _showSuccess('You have joined the event successfully.');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      _showError('Failed to join event: ${e.message}');
    } catch (e) {
      _showError('Failed to join event: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.3), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('Join Event', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildField(controller: nameController, label: 'Name', icon: Icons.person),
            const SizedBox(height: 16),
            _buildField(controller: surnameController, label: 'Surname', icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildField(
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isSaving ? null : _joinEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isSaving ? 'Joining...' : 'Confirm Join',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
