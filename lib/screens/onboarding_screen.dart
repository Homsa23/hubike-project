import 'package:flutter/material.dart';
import 'home.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. The body is now a Container that paints the background image
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bike.jpg'), 
            fit: BoxFit.cover, // Stretches it across the whole screen
            // Darkens the image a bit so your logo and white text don't get lost in the bright spots
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                Image.asset(
                  'assets/logo.png',
                  height: 150,
                  width: 150,
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Welcome to HUBIKE!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, 
                  ),
                ),
                
                const SizedBox(height: 16),

                const Text(
                  'Join the biggest cycling community in Annaba.\nBuy equipment, join events, and ride together!',
                  textAlign: TextAlign.center, 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),

                const Spacer(), 
                
                SizedBox(
                  width: double.infinity,
                  height: 50, 
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}