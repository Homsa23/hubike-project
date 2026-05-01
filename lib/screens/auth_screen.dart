import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;
  bool _isGroupLeader = false;
  bool _isGoogleSignInLoading = false;
  bool _isOtpLoading = false;
  String? _verificationId;
  UserCredential? _pendingUserCredential;
  String? _pendingImageUrl;
  File? _selectedImage;
  final TextEditingController phoneNumberSignInController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

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
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      // Check if phone number already exists in Firestore
      final phoneQuery = await _firestore.collection('user').where('phone_number', isEqualTo: phone).get();
      if (phoneQuery.docs.isNotEmpty) {
        _showError('An account with this phone number already exists.');
        return;
      }

      // Create Firebase Auth user with email/password
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _pendingUserCredential = userCredential;

      // Upload image to Firebase Storage if selected
      if (_selectedImage != null) {
        try {
          final uid = userCredential.user!.uid;
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
          await storageRef.putFile(_selectedImage!);
          _pendingImageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint('Failed to upload image: $e');
          _pendingImageUrl = null;
        }
      }

      // Start phone verification
      await _verifyPhoneNumber(phone);

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showError('An account with this email already exists.');
      } else if (e.code == 'weak-password') {
        _showError('Password is too weak.');
      } else {
        _showError('Failed to create account: ${e.message}');
      }
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

  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    setState(() => _isOtpLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+213$phoneNumber', // Algeria country code
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification on some Android devices
        await _linkPhoneCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isOtpLoading = false);
        _showError('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isOtpLoading = false;
        });
        _showOtpDialog();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF39FF14), width: 1),
        ),
        title: const Text(
          'Verify Phone Number',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-digit code sent to your phone',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF39FF14),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
                ),
                counterStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupPendingUser();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (otpController.text.length == 6) {
                Navigator.pop(context);
                await _verifyOtp(otpController.text);
              } else {
                _showError('Please enter a 6-digit code');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtp(String smsCode) async {
    if (_verificationId == null || _pendingUserCredential == null) {
      _showError('Verification session expired. Please try again.');
      return;
    }

    setState(() => _isOtpLoading = true);

    try {
      // Create phone credential
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _linkPhoneCredential(phoneCredential);
    } on FirebaseAuthException catch (e) {
      setState(() => _isOtpLoading = false);
      if (e.code == 'invalid-verification-code') {
        _showError('Invalid code. Please try again.');
        _showOtpDialog();
      } else {
        _showError('Verification failed: ${e.message}');
        _cleanupPendingUser();
      }
    } catch (e) {
      setState(() => _isOtpLoading = false);
      _showError('An error occurred: $e');
      _cleanupPendingUser();
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential phoneCredential) async {
    try {
      final user = _pendingUserCredential!.user!;

      // Link phone credential to existing email/password account
      await user.linkWithCredential(phoneCredential);

      // NOW create Firestore document after successful verification
      final uid = user.uid;
      final phone = phoneNumberController.text.trim();
      final email = emailController.text.trim();

      final userData = {
        'uid': uid,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'birthdate': birthDateController.text.trim(),
        'residence': residenceController.text.trim(),
        'phone_number': phone,
        'email': email,
        'image': _pendingImageUrl ?? '',
        'coins': 0,
        'isGroupLeader': _isGroupLeader,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('user').doc(uid).set(userData);

      setState(() => _isOtpLoading = false);

      _showSuccess('Account created and verified successfully!');

      // Clear pending data
      _verificationId = null;
      _pendingUserCredential = null;
      _pendingImageUrl = null;

      // Return user data to HomeScreen
      Navigator.pop(context, userData);
    } on FirebaseAuthException catch (e) {
      setState(() => _isOtpLoading = false);
      if (e.code == 'provider-already-linked') {
        _showError('This phone number is already linked to another account.');
      } else {
        _showError('Failed to link phone: ${e.message}');
      }
      _cleanupPendingUser();
    } catch (e) {
      setState(() => _isOtpLoading = false);
      _showError('Failed to complete registration: $e');
      _cleanupPendingUser();
    }
  }

  void _cleanupPendingUser() {
    // Delete the pending user if verification failed
    _pendingUserCredential?.user?.delete();
    _verificationId = null;
    _pendingUserCredential = null;
    _pendingImageUrl = null;
    setState(() => _isOtpLoading = false);
  }

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _signInUser() async {
    final phone = phoneNumberSignInController.text.trim();
    final password = passwordController.text;

    try {
      // Look up user by phone number to get their email
      final phoneQuery = await _firestore.collection('user').where('phone_number', isEqualTo: phone).limit(1).get();
      
      if (phoneQuery.docs.isEmpty) {
        _showError('No account found for this phone number.');
        return;
      }

      final userData = phoneQuery.docs.first.data();
      final email = userData['email'] as String?;
      
      if (email == null || email.isEmpty) {
        _showError('Account email not found. Please contact support.');
        return;
      }

      // Sign in with Firebase Auth using email/password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showSuccess('Signed in successfully.');

      // Return user data to HomeScreen
      Navigator.pop(context, userData);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('No account found with this phone number.');
      } else if (e.code == 'wrong-password') {
        _showError('Wrong password. Please try again.');
      } else {
        _showError('Sign in failed: ${e.message}');
      }
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
              const SizedBox(height: 16),

              // Group Leader Toggle (only for sign up)
              if (!isSignIn) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isGroupLeader
                          ? const Color(0xFF39FF14).withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isGroupLeader ? Icons.admin_panel_settings : Icons.person_outline,
                        color: _isGroupLeader ? const Color(0xFF39FF14) : Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Register as Group Leader',
                              style: TextStyle(
                                color: _isGroupLeader ? const Color(0xFF39FF14) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Host events & manage shop inventory',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isGroupLeader,
                        onChanged: (value) {
                          setState(() {
                            _isGroupLeader = value;
                          });
                        },
                        activeColor: const Color(0xFF39FF14),
                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

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
                          _isGroupLeader = false;
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
                  onPressed: _isGoogleSignInLoading ? null : _signInWithGoogle,
                  icon: _isGoogleSignInLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF39FF14),
                          ),
                        )
                      : const Text("G", style: TextStyle(fontSize: 18)),
                  label: Text(_isGoogleSignInLoading ? "Signing in..." : "Continue with Google"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF39FF14),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleSignInLoading = true);

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        setState(() => _isGoogleSignInLoading = false);
        return;
      }

      // Obtain authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        _showError('Failed to sign in with Google');
        setState(() => _isGoogleSignInLoading = false);
        return;
      }

      final uid = user.uid;
      final email = user.email ?? googleUser.email;
      final displayName = user.displayName ?? googleUser.displayName ?? '';

      // Parse name into first and last
      String firstName = '';
      String lastName = '';
      if (displayName.isNotEmpty) {
        final nameParts = displayName.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('user').doc(uid).get();

      Map<String, dynamic> userData;

      if (!userDoc.exists) {
        // Create new user document
        userData = {
          'uid': uid,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': '',
          'birthdate': '',
          'residence': '',
          'image': user.photoURL ?? '',
          'coins': 0,
          'isGroupLeader': false, // Default to false for Google sign-ups
          'created_at': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('user').doc(uid).set(userData);
      } else {
        // User exists, get their data
        userData = userDoc.data() as Map<String, dynamic>;
      }

      _showSuccess('Signed in successfully with Google');

      // Navigate to main app screen
      if (mounted) {
        Navigator.pop(context, userData);
      }
    } on FirebaseAuthException catch (e) {
      _showError('Google Sign-In failed: ${e.message}');
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInLoading = false);
      }
    }
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
