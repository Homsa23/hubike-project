import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;
  final TextEditingController phoneNumberSignInController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  File? _selectedImage;

  @override
  void dispose() {
    phoneNumberSignInController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    residenceController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // Validation methods
  String? _validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return "Phone number is required";
    }
    if (phone.length != 10) {
      return "Phone number must be 10 digits";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return "Phone number can only contain digits";
    }
    return null;
  }

  String? _validateName(String name) {
    if (name.isEmpty) {
      return "Name is required";
    }
    if (RegExp(r'[0-9]').hasMatch(name)) {
      return "Name cannot contain numbers";
    }
    return null;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return "Email is required";
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      return "Please enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return "Password is required";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  String? _validateBirthDate(String date) {
    if (date.isEmpty) {
      return "Birth date is required";
    }
    if (!RegExp(r'^(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[012])/[0-9]{4}$')
        .hasMatch(date)) {
      return "Please use DD/MM/YYYY format";
    }
    return null;
  }

  String? _validateAddress(String address) {
    if (address.isEmpty) {
      return "Address is required";
    }
    if (address.length < 5) {
      return "Please enter a valid address";
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar( 
        content: Text(message),
        backgroundColor: const Color(0xFF39FF14),
        duration: const Duration(seconds: 2),
      ),
    );
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

  Future<void> _submitForm() async {
    if (isSignIn) {
      final phoneError = _validatePhoneNumber(phoneNumberSignInController.text);
      final passwordError = _validatePassword(passwordController.text);

      if (phoneError != null) {
        _showError(phoneError);
        return;
      }
      if (passwordError != null) {
        _showError(passwordError);
        return;
      }

      await _signInUser();
    } else {
      final firstNameError = _validateName(firstNameController.text);
      final lastNameError = _validateName(lastNameController.text);
      final birthDateError = _validateBirthDate(birthDateController.text);
      final addressError = _validateAddress(residenceController.text);
      final phoneError = _validatePhoneNumber(phoneNumberController.text);
      final emailError = _validateEmail(emailController.text);
      final passwordError = _validatePassword(passwordController.text);

      if (firstNameError != null) {
        _showError(firstNameError);
        return;
      }
      if (lastNameError != null) {
        _showError(lastNameError);
        return;
      }
      if (birthDateError != null) {
        _showError(birthDateError);
        return;
      }
      if (addressError != null) {
        _showError(addressError);
        return;
      }
      if (phoneError != null) {
        _showError(phoneError);
        return;
      }
      if (emailError != null) {
        _showError(emailError);
        return;
      }
      if (passwordError != null) {
        _showError(passwordError);
        return;
      }

      await _createUserAccount();
    }
  }

  Future<void> _createUserAccount() async {
    final phone = phoneNumberController.text.trim();
    // Create one document inside the existing 'user' collection.
    // This does not create a separate collection for each user.
    final userRef = _firestore.collection('user').doc(phone);

    try {
      final snapshot = await userRef.get();
      if (snapshot.exists) {
        _showError('An account with this phone number already exists.');
        return;
      }

      String? imageUrl;
      if (_selectedImage != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/$phone.jpg');
        await storageRef.putFile(_selectedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await userRef.set({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'birthdate': birthDateController.text.trim(),
        'residence': residenceController.text.trim(),
        'phone_number': phone,
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'image': imageUrl ?? '',
        'coins': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSuccess('Account created successfully.');
      setState(() {
        isSignIn = true;
        phoneNumberSignInController.text = phone;
        passwordController.clear();
        _selectedImage = null;
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _showError('Firestore is temporarily unavailable. Please try again in a few seconds.');
        return;
      }
      _showError('Failed to save account: ${e.message}');
    } catch (e) {
      _showError('Failed to save account: $e');
    }
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _signInUser() async {
    final phone = phoneNumberSignInController.text.trim();
    final password = passwordController.text;
    final userRef = _firestore.collection('user').doc(phone);

    try {
      final snapshot = await userRef.get();
      if (!snapshot.exists) {
        _showError('No account found for this phone number.');
        return;
      }

      final storedPassword = snapshot.data()?['password'] as String?;
      if (storedPassword == null || storedPassword != password) {
        _showError('Wrong password. Please try again.');
        return;
      }

      _showSuccess('Signed in successfully.');
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        _showError('Firestore is temporarily unavailable. Please try again in a few seconds.');
        return;
      }
      _showError('Sign in failed: ${e.message}');
    } catch (e) {
      _showError('Sign in failed: $e');
    }
  }

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
        shape: Border(
          bottom: BorderSide(color: Colors.white24, width: 0.2),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF39FF14).withOpacity(0.2),
                        const Color(0xFF39FF14).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF39FF14),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF39FF14),
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Title
              Text(
                isSignIn ? "Welcome Back!" : "Join HUBIKE",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSignIn
                    ? "Sign in to your account"
                    : "Create your cycling profile",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFA1A1AA),
                ),
              ),
              const SizedBox(height: 32),

              // Name fields (only for sign up)
              if (!isSignIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: firstNameController,
                        label: "First Name",
                        icon: Icons.person,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: lastNameController,
                        label: "Last Name",
                        icon: Icons.person,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: birthDateController,
                  label: "Birth Date (DD/MM/YYYY)",
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: residenceController,
                  label: "Residence (Address)",
                  icon: Icons.home,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneNumberController,
                  label: "Phone Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF39FF14).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.camera_alt, color: const Color(0xFF39FF14)),
                    title: Text(
                      _selectedImage != null ? "Image Selected" : "Select Profile Picture",
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: _selectedImage != null
                        ? CircleAvatar(
                            backgroundImage: FileImage(_selectedImage!),
                            radius: 20,
                          )
                        : const Icon(Icons.add_a_photo, color: Color(0xFF39FF14)),
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone number field (only for sign in)
              if (isSignIn) ...[
                _buildTextField(
                  controller: phoneNumberSignInController,
                  label: "Phone Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Email field (only for sign up)
              if (!isSignIn) ...[
                _buildTextField(
                  controller: emailController,
                  label: "Email Address",
                  icon: Icons.mail,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
              ],

              // Password field
              _buildTextField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Sign In / Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isSignIn ? "SIGN IN" : "CREATE ACCOUNT",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle Sign In / Sign Up
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSignIn
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isSignIn = !isSignIn;
                          phoneNumberSignInController.clear();
                          passwordController.clear();
                          firstNameController.clear();
                          lastNameController.clear();
                          birthDateController.clear();
                          residenceController.clear();
                          phoneNumberController.clear();
                          emailController.clear();
                          _selectedImage = null;
                        });
                      },
                      child: Text(
                        isSignIn ? "Sign Up" : "Sign In",
                        style: const TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white10,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      "or",
                      style: TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.white10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Social Sign In
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Text("G", style: TextStyle(fontSize: 18)),
                  label: const Text("Continue with Google"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF39FF14),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
