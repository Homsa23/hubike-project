import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_model.dart';
import 'cart_state.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  Future<String> _fetchShopName(String uid) async {
    if (uid.isEmpty) return 'UNKNOWN SHOP';
    final firestore = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
    try {
      final leaderDoc = await firestore.collection('group_leader').doc(uid).get();
      if (leaderDoc.exists) {
        final data = leaderDoc.data() as Map<String, dynamic>? ?? {};
        final groupName = data['groupName']?.toString() ?? '';
        if (groupName.trim().isNotEmpty) return groupName.trim().toUpperCase();
      }
      
      // Fallback to the User collection if they don't have a specific groupName
      final userDoc = await firestore.collection('user').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final firstName = data['first_name']?.toString() ?? '';
        final lastName = data['last_name']?.toString() ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim().toUpperCase();
        }
      }
    } catch (e) {
      // Ignore errors and fallback
    }
    return 'UNKNOWN SHOP';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            bottom: 150, // Leave space for bottom button
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
                            color: const Color(0xFF121212).withAlpha(30),
                            
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
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // SHOP NAME INDICATOR (Group Leader)
                  FutureBuilder<String>(
                    future: _fetchShopName(product.groupLeaderId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Color(0xFF39FF14), strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LOADING SHOP...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, color: Color(0xFF39FF14), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'SHOP: ${snapshot.data ?? 'UNKNOWN'}',
                              style: const TextStyle(
                                color: Color(0xFF39FF14),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                                  style: GoogleFonts.rajdhani(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Product Condition',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white54,
                                    fontSize: 11,
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          color: Colors.white70,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.price.toStringAsFixed(0)} DZD',
                          style: GoogleFonts.rajdhani(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Shop Balance Display
                  StreamBuilder<DocumentSnapshot>(
                    stream: product.groupLeaderId.isNotEmpty && FirebaseAuth.instance.currentUser != null
                        ? FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
                            .collection('user')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      int shopBalance = 0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final leaderCoinsMap = userData['leaderCoins'] as Map<String, dynamic>?;
                        if (leaderCoinsMap != null) {
                          shopBalance = (leaderCoinsMap[product.groupLeaderId] as num?)?.toInt() ?? 0;
                        }
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          'Your Balance for this Shop: $shopBalance Coins',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                  // Add to Cart Button
                  ListenableBuilder(
                    listenable: cartState,
                    builder: (context, _) {
                      int cartQty = cartState.getQuantity(product.id);
                      int visualStock = product.quantity - cartQty;

                      if (visualStock <= 0) {
                        return ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.redAccent,
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
                              Icon(Icons.remove_shopping_cart, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ElevatedButton(
                        onPressed: () {
                          cartState.addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to cart! (${visualStock - 1} left)'),
                              backgroundColor: const Color(0xFF39FF14),
                              duration: const Duration(seconds: 2),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'ADD TO CART',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
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
              style: GoogleFonts.montserrat(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
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
