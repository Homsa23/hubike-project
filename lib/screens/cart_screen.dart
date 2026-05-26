import 'package:flutter/material.dart';
import 'cart_state.dart';
import 'product_model.dart';
import 'order_form_screen.dart';
import 'auth_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'MY CART',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Dynamically read the group leader ID from the first item in cart
          ListenableBuilder(
            listenable: cartState,
            builder: (context, _) {
              final String currentLeaderId = cartState.items.isNotEmpty 
                  ? cartState.items.first.groupLeaderId 
                  : '';

              if (currentLeaderId.isEmpty || FirebaseAuth.instance.currentUser == null) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
                        .collection('user')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  int shopBalance = 0;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final leaderCoinsMap = userData['leaderCoins'] as Map<String, dynamic>?;
                    if (leaderCoinsMap != null) {
                      shopBalance = (leaderCoinsMap[currentLeaderId] as num?)?.toInt() ?? 0;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF39FF14), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFF39FF14), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$shopBalance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: cartState,
        builder: (context, _) {
          if (cartState.items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            );
          }
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return _buildCartItem(item, context);
                  },
                ),
              ),
              _buildBottomCheckout(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(Product item, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 80,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(item.imageUrl, fit: BoxFit.cover)
                  : Container(color: Colors.black26, child: const Icon(Icons.image, color: Colors.white24)),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} DZD',
                  style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              cartState.removeProduct(item);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item removed'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: const Color(0xFF39FF14).withOpacity(0.3))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text(
                  '${cartState.totalPrice.toStringAsFixed(0)} DZD',
                  style: const TextStyle(color: Color(0xFF39FF14), fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (cartState.items.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                   return;
                }

                // Check Authentication before checkout
                if (FirebaseAuth.instance.currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log in to complete your purchase!'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  ).then((_) {
                    // After returning from AuthScreen, if logged in, proceed
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderFormScreen(products: List.from(cartState.items), fromCart: true),
                        ),
                      );
                    }
                  });
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderFormScreen(products: List.from(cartState.items), fromCart: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('BUY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
