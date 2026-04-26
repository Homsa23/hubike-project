import 'package:flutter/material.dart';
import 'dart:ui';
import 'event_model.dart'; // Make sure this points to your real model!

class InsideEventScreen extends StatelessWidget {
  final HubikeEvent event;

  const InsideEventScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505), 

      // ---------------------------------------------------------
      // THE MAIN CONTENT (Scrollable)
      // ---------------------------------------------------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. THE DATE (Neon Green, Spaced out)
              Text(
                event.date.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF39FF14), // Neon
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0, // tracking-widest
                ),
              ),
              
              const SizedBox(height: 8),

              // 2. THE TITLE (Giant, Bold, White)
              Text(
                event.eventName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.0, // leading-none
                ),
              ),

              const SizedBox(height: 24),

              // 3. THE 3 STAT BOXES (Row with Expanded)
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      "PRICE", 
                      event.price == 0 ? "FREE" : "${event.price} DA", 
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12), // gap-3
                  Expanded(
                    child: _buildStatBox(
                      "REWARD", 
                      "+${event.coinsToEarn}", 
                      const Color(0xFF39FF14), // Neon green text for coins
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatBox(
                      "LEVEL", 
                      "HARD", 
                      Colors.redAccent, // Red text for hard level
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 4. MISSION BRIEF TITLE
              const Text(
                "MISSION BRIEF",
                style: TextStyle(
                  color: Colors.white54, // text-zinc-400
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              // 5. THE ACTUAL DESCRIPTION
              Text(
                event.description,
                style: const TextStyle(
                  color: Colors.white70, // text-zinc-300
                  fontSize: 15,
                  height: 1.6, // leading-relaxed
                ),
              ),

              // Add a big empty space at the bottom so the text doesn't get 
              // hidden permanently behind the frosted glass navbar
              const SizedBox(height: 120), 
            ],
          ),
        ),
      ),
      
      // ---------------------------------------------------------
      // THE FROSTED GLASS NAVBAR (Untouched, exactly as you had it)
      // ---------------------------------------------------------
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 30.0),
            decoration: BoxDecoration(
              color: const Color(0xFF050505).withOpacity(0.9), 
              border: const Border(
                top: BorderSide(color: Color(0xFF27272A), width: 1), 
              ),
            ),
            child: GestureDetector(
              onTap: () {
                print("JOIN RIDE BUTTON CLICKED!");
              },
              child: Container(
                width: double.infinity, 
                padding: const EdgeInsets.symmetric(vertical: 16.0), 
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14), 
                  borderRadius: BorderRadius.circular(16), 
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withOpacity(0.3), 
                      blurRadius: 30, 
                      spreadRadius: 0,
                      offset: const Offset(0, 0), 
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.flash_on, color: Colors.black, size: 24),
                    SizedBox(width: 8), 
                    Text(
                      "JOIN RIDE",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1.2, 
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // HELPER METHOD: Draws the 3 dark glass boxes perfectly
  // ---------------------------------------------------------
  Widget _buildStatBox(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), // Super subtle dark glass background
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.white12, width: 1), // border-zinc-800
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54, // text-zinc-500
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor, 
              fontSize: 18,
              fontWeight: FontWeight.w900, // font-display bold
            ),
          ),
        ],
      ),
    );
  }
}