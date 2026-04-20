import 'package:flutter/material.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header with Title and Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "GEAR ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextSpan(
                      text: "DROP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF39FF14),
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Color(0xFF39FF14),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.monetization_on,
                      color: Color(0xFF39FF14),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "2,450 PTS",
                      style: TextStyle(
                        color: Color(0xFF39FF14),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Featured Item
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121212).withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withOpacity(0.05),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Image with gradient background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 192,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF39FF14).withOpacity(0.1),
                            const Color(0xFF050505),
                          ],
                        ),
                      ),
                    ),
                    Image.network(
                      "https://images.unsplash.com/photo-1572004944458-18e385dc6201?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80",
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shield,
                          color: Color(0xFF39FF14),
                          size: 80,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "AERO-X CARBON HELMET",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Ultra-lightweight. High visibility neon accents.",
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFA1A1AA),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "UNLOCK FOR 15,000 PTS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Grid Items
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGridItem(
                title: "NIGHT RIDER JERSEY",
                icon: Icons.checkroom,
                price: "5,000 PTS",
              ),
              _buildGridItem(
                title: "1000LM LED LIGHT",
                icon: Icons.lightbulb,
                price: "3,200 PTS",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String title,
    required IconData icon,
    required String price,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF52525B),
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF39FF14),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
