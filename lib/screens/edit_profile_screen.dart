import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fill with existing infos
    firstNameController.text = widget.userData['first_name']?.toString() ?? '';
    lastNameController.text = widget.userData['last_name']?.toString() ?? '';
    birthDateController.text = widget.userData['birthdate']?.toString() ?? '';
    residenceController.text = widget.userData['residence']?.toString() ?? '';
    phoneNumberController.text = widget.userData['phone_number']?.toString() ?? '';
    _currentImageUrl = widget.userData['image']?.toString();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    residenceController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String phone) {
    if (phone.isEmpty) return "Phone number is required";
    if (phone.length != 10) return "Phone number must be 10 digits";
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) return "Phone number can only contain digits";
    return null;
  }

  String? _validateName(String name) {
    if (name.isEmpty) return "Name is required";
    if (RegExp(r'[0-9]').hasMatch(name)) return "Name cannot contain numbers";
    return null;
  }

  String? _validateBirthDate(String date) {
    if (date.isEmpty) return "Birth date is required";
    if (!RegExp(r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[012])/[0-9]{4}$').hasMatch(date)) {
      return "Please use DD/MM/YYYY format";
    }
    return null;
  }

  String? _validateAddress(String address) {
    if (address.isEmpty) return "Residence is required";
    if (address.length < 5) return "Please enter a valid address";
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _updateProfile() async {
    final firstNameError = _validateName(firstNameController.text);
    final lastNameError = _validateName(lastNameController.text);
    final birthDateError = _validateBirthDate(birthDateController.text);
    final addressError = _validateAddress(residenceController.text);
    final phoneError = _validatePhoneNumber(phoneNumberController.text);

    if (firstNameError != null) { _showError(firstNameError); return; }
    if (lastNameError != null) { _showError(lastNameError); return; }
    if (birthDateError != null) { _showError(birthDateError); return; }
    if (addressError != null) { _showError(addressError); return; }
    if (phoneError != null) { _showError(phoneError); return; }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
      
      String? imageUrl = _currentImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/dopk2m742/image/upload'),
          );

          request.fields['upload_preset'] = 'hubike_shop';
          request.files.add(await http.MultipartFile.fromPath('file', _selectedImage!.path));

          final response = await request.send();

          if (response.statusCode == 200) {
            final responseData = await response.stream.bytesToString();
            final jsonData = json.decode(responseData);
            imageUrl = jsonData['secure_url'];
          } else {
            throw Exception('Cloudinary upload failed with status ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Failed to upload image to Cloudinary: $e');
        }
      }

      // Update the user document
      await firestore.collection('user').doc(user.uid).update({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'birthdate': birthDateController.text.trim(),
        'residence': residenceController.text.trim(),
        'phone_number': phoneNumberController.text.trim(),
        if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF39FF14)),
      );
      
      // Return true to indicate success and trigger reload
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFFA1A1AA)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'MODIFY PROFILE',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update your information",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF39FF14), width: 2),
                      image: _selectedImage != null
                          ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                          : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_currentImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: (_selectedImage == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                        ? const Icon(Icons.add_a_photo, color: Color(0xFF39FF14), size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: birthDateController,
                label: 'Birth Date (DD/MM/YYYY)',
                icon: Icons.cake_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: residenceController,
                label: 'Residence (Wilaya)',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: phoneNumberController,
                label: 'Phone Number (10 digits)',
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
