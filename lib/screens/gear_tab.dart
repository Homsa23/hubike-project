import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_model.dart'; // Ensure this path correctly resolves to your Product model
import 'product_detail.dart';
import 'cart_state.dart';
import 'cart_screen.dart';
import 'order_form_screen.dart';

class GearTab extends StatelessWidget {
  final String groupLeaderId;

  const GearTab({Key? key, required this.groupLeaderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Minimalist dark theme base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'GEAR',
          style: TextStyle(
            color: Color(0xFF39FF14), // Neon green accent
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: cartState,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Color(0xFF39FF14)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                    },
                  ),
                  if (cartState.items.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartState.items.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: groupLeaderId.isNotEmpty
            ? FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'default',
                )
                .collection('product')
                .where('groupLeaderId', isEqualTo: groupLeaderId)
                .snapshots()
            : FirebaseFirestore.instanceFor(
                  app: Firebase.app(),
                  databaseId: 'default',
                ).collection('product').snapshots(),
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF39FF14),
              ),
            );
          }

          // Error State
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading gear.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          // Empty State gracefully handled
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: const Color(0xFF39FF14).withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Gear Available Yet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new products.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // Responsive 2-column GridView
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.6, // Adjusted to 0.6 to prevent bottom overflow
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final product = Product.fromFirestore(doc);
              return _buildProductCard(context, product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Slightly lighter dark for card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3), // Neon green subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39FF14).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.black26,
                    child: _buildImage(product.imageUrl),
                  ),
                  // Discount Badge (Cyan Accent)
                  if (product.discountCoins > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'Max -${product.discountCoins} Coins',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // --- Details Section ---
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand & Product Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.brand.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Price
                    Text(
                      'DZD ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF39FF14), // Neon green price
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action Buttons
                    // Action Buttons
                    AnimatedBuilder(
                      animation: cartState,
                      builder: (context, child) {
                        int cartQty = cartState.getQuantity(product.id);
                        int visualStock = product.quantity - cartQty;
                        bool outOfStock = visualStock <= 0;

                        return Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: outOfStock
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'OUT OF\nSTOCK',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          cartState.addProduct(product);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added to cart! (${visualStock - 1} left)'),
                                              backgroundColor: const Color(0xFF39FF14),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: const Color(0xFF39FF14),
                                          elevation: 0,
                                          side: const BorderSide(color: Color(0xFF39FF14), width: 1),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Icon(Icons.add_shopping_cart, size: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: outOfStock ? null : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderFormScreen(products: [product], fromCart: false),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: outOfStock ? Colors.grey[800] : const Color(0xFF39FF14),
                                    foregroundColor: outOfStock ? Colors.white54 : Colors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    outOfStock ? 'UNAVAILABLE' : 'Buy Equipment', 
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // Graceful handling for missing or broken image URLs
  Widget _buildImage(String url) {
    if (url.trim().isEmpty) {
      return Center(
        child: Icon(
          Icons.shopping_bag,
          size: 48,
          color: const Color(0xFF39FF14).withOpacity(0.5), // Neon icon fallback
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: const Color(0xFF39FF14).withOpacity(0.5),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF39FF14),
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}
