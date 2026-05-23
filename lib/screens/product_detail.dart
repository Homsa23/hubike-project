import 'package:flutter/material.dart';
import 'product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            bottom: 120, // Leave space for bottom button
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO IMAGE
                  Stack(
                    children: [
                      Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          image: product.imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(product.imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: product.imageUrl.isEmpty
                            ? const Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                                size: 80,
                              )
                            : null,
                      ),
                      // Gradient overlay at bottom
                      Container(
                        height: 320,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF050505).withAlpha(230),
                            ],
                          ),
                        ),
                      ),
                      // Back button
                      Positioned(
                        top: 50,
                        left: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212).withAlpha(180),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      // Stock badge (top right)
                      Positioned(
                        top: 50,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withAlpha(30),
                            border: Border.all(color: const Color(0xFF39FF14).withAlpha(100)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'STOCK: ${product.quantity}',
                            style: const TextStyle(
                              color: Color(0xFF39FF14),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      // Title on image
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Text(
                          product.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // STATS ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildStatCard('BRAND', product.brand.toUpperCase(), Icons.branding_watermark),
                        const SizedBox(width: 10),
                        _buildStatCard('CATEGORY', product.category.toUpperCase(), Icons.category),
                        const SizedBox(width: 10),
                        _buildStatCard('DISCOUNT', '-${product.discountCoins} COINS', Icons.monetization_on),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // DESCRIPTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ABOUT',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // CONDITION CARD
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF39FF14).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Color(0xFF39FF14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.condition.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Product Condition',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 140), // Extra space to scroll past fixed bottom button
                ],
              ),
            ),
          ),

          // BOTTOM ADD TO CART BUTTON
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050505).withAlpha(240),
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(10)),
                ),
              ),
              child: Column(
                children: [
                  // Price display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.price.toStringAsFixed(0)} DZD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Add to Cart Button
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement cart logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart! (Coming soon)'),
                          backgroundColor: Color(0xFF39FF14),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'ADD TO CART',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple stat card widget matching Event details
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
