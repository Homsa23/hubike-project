import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
import 'screens/onboarding_screen.dart'; 
import 'screens/inside_event.dart';
import 'screens/event_model.dart';

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
      home: InsideEventScreen(
        event: HubikeEvent(
          id: "test_123",
          eventName: "NEON CITY\nSPRINT",
          description: "We are taking over the downtown grid tonight. High-speed, high-intensity sprint through the neon-lit sectors.",
          date: "TONIGHT • 22:00",
          startingPoint: "DOWNTOWN PLAZA",
          price: 0,
          coinsToEarn: 100,
          capacity: 100,
          categoryId: "sprint",
          priceInCoins: 0,
        ), // Closes HubikeEvent
      ), // <--- ADDED THIS! Closes InsideEventScreen
    ); // Closes MaterialApp
  }
}