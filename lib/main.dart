import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';

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
        primarySwatch: Colors.green, 
        useMaterial3: true,
      ),
      home: OnboardingScreen(),
    ); // Closes MaterialApp
  }
}