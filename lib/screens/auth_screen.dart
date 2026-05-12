import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:table_calendar/table_calendar.dart';
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
  File? _selectedImage;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController residenceController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    residenceController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    groupNameController.dispose();
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
      final emailError = _validateEmail(emailController.text);
      final passwordError = _validatePassword(passwordController.text);

      if (emailError != null) {
        _showError(emailError);
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

      // Validate Group Name if Group Leader
      if (_isGroupLeader && groupNameController.text.trim().isEmpty) {
        _showError('Group Name is required for Leaders');
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

      final uid = userCredential.user!.uid;

      // Upload image to Firebase Storage if selected
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
          await storageRef.putFile(_selectedImage!);
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          debugPrint('Failed to upload image: $e');
          imageUrl = null;
        }
      }

      // Create user data
      final userData = {
        'uid': uid,
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'birthdate': birthDateController.text.trim(),
        'residence': residenceController.text.trim(),
        'phone_number': phone,
        'email': email,
        'image': imageUrl ?? '',
        'coins': 0,
        'isGroupLeader': _isGroupLeader,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Save to users collection
      await _firestore.collection('user').doc(uid).set(userData);

      // If Group Leader, also create document in group_leader collection
      if (_isGroupLeader) {
        final leaderData = {
          'groupleaderID': uid,
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'groupName': groupNameController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
        };
        await _firestore.collection('group_leader').doc(uid).set(leaderData);
      }

      _showSuccess('Account created successfully!');

      // Return user data to HomeScreen
      Navigator.pop(context, userData);

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

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  Future<void> _signInUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      // Sign in with Firebase Auth using email/password directly
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('user').doc(uid).get();
      
      if (!userDoc.exists) {
        _showError('User data not found. Please contact support.');
        return;
      }

      final userData = userDoc.data()!;

      _showSuccess('Signed in successfully.');

      // Return user data to HomeScreen
      Navigator.pop(context, userData);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('No account found with this email.');
      } else if (e.code == 'wrong-password') {
        _showError('Wrong password. Please try again.');
      } else if (e.code == 'invalid-credential') {
        _showError('Invalid email or password.');
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
                _buildDatePickerField(),
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

              // Email field (for sign in)
              if (isSignIn) ...[
                _buildTextField(
                  controller: emailController,
                  label: "Email Address",
                  icon: Icons.mail,
                  keyboardType: TextInputType.emailAddress,
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
                // Group Name field (only for Group Leaders)
                if (_isGroupLeader) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: groupNameController,
                    label: 'Group Name (e.g., Elite Riders)',
                    icon: Icons.groups,
                  ),
                ],
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
                          emailController.clear();
                          passwordController.clear();
                          firstNameController.clear();
                          lastNameController.clear();
                          birthDateController.clear();
                          residenceController.clear();
                          phoneNumberController.clear();
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

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: () => _showCalendarPicker(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF39FF14).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: birthDateController,
          enabled: false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Birth Date (DD/MM/YYYY)',
            hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
            prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFF39FF14)),
            suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            disabledBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  void _showCalendarPicker() {
    DateTime? selectedDay;
    DateTime focusedDay = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Generate year list from 1900 to current year
          final currentYear = DateTime.now().year;
          final years = List.generate(currentYear - 1900 + 1, (index) => currentYear - index);

          return Dialog(
            backgroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: const Color(0xFF39FF14).withOpacity(0.3),
                width: 1,
              ),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Birth Date',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Year Picker Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF39FF14).withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: focusedDay.year,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF39FF14)),
                          onChanged: (year) {
                            if (year != null) {
                              setDialogState(() {
                                focusedDay = DateTime(year, focusedDay.month, 1);
                              });
                            }
                          },
                          items: years.map((year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                year.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 320,
                      child: TableCalendar(
                        firstDay: DateTime(1900),
                        lastDay: DateTime.now(),
                        focusedDay: focusedDay,
                        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                        onDaySelected: (selected, focused) {
                          setDialogState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          setDialogState(() {
                            focusedDay = focused;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: const TextStyle(color: Colors.white),
                          weekendTextStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(color: Colors.white),
                          selectedDecoration: const BoxDecoration(
                            color: Color(0xFF39FF14),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          formatButtonVisible: false,
                          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: const Color(0xFF39FF14).withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedDay != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF39FF14).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Selected: ${_formatDate(selectedDay!)}',
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white54,
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedDay != null
                                ? () {
                                    setState(() {
                                      birthDateController.text = _formatDate(selectedDay!);
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF39FF14),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
