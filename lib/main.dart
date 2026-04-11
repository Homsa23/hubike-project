import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Keep Firebase import
import 'firebase_options.dart'; // Keep Firebase options
import 'screens/onboarding_screen.dart'; // Your new import!

void main() async {
  // 1. Ensure Flutter bindings are initialized (Required for Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase for Hubike
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hubike',
      theme: ThemeData(
        primarySwatch: Colors.green, // Great color choice for a cycling app!
        useMaterial3: true,
      ),
      home: const OnboardingScreen(), // Your new screen is now the home!
    );
  }
}