import 'package:flutter/material.dart';
import 'product_model.dart';
import 'order_model.dart';
import 'cart_state.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderFormScreen extends StatefulWidget {
  final List<Product> products;
  final bool fromCart;

  const OrderFormScreen({super.key, required this.products, this.fromCart = false});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _coinsInputController = TextEditingController();
  
  bool _isSubmitting = false;

  int _availableCoins = 0;
  bool _useCoins = false;
  final double _coinValue = 10.0;

  @override
  void initState() {
    super.initState();
    _fetchUserCoins();
  }

  Future<void> _fetchUserCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.products.isEmpty) return;

    final leaderId = widget.products.first.groupLeaderId;
    final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
        .collection('user')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      final leaderCoinsMap = data['leaderCoins'] as Map<String, dynamic>?;
      if (leaderCoinsMap != null) {
        setState(() {
          _availableCoins = (leaderCoinsMap[leaderId] as num?)?.toInt() ?? 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _wilayaController.dispose();
    _coinsInputController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    final originalTotal = widget.fromCart 
        ? cartState.totalPrice 
        : widget.products.fold(0.0, (sum, item) => sum + item.price);

    double finalTotal = originalTotal;
    int coinsToDeduct = 0;

    if (_useCoins && _availableCoins > 0) {
      int inputCoins = int.tryParse(_coinsInputController.text) ?? 0;
      if (inputCoins > _availableCoins) inputCoins = _availableCoins;
      
      double requestedDiscount = inputCoins * _coinValue;
      
      if (requestedDiscount >= originalTotal) {
        finalTotal = 0;
        coinsToDeduct = (originalTotal / _coinValue).ceil();
      } else {
        finalTotal = originalTotal - requestedDiscount;
        coinsToDeduct = inputCoins;
      }
    }

    final order = OrderModel(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      wilaya: _wilayaController.text.trim(),
      orderDate: DateTime.now(),
      products: widget.products,
      totalAmount: finalTotal,
    );

    try {
      await order.saveToFirestore();

      // Deduct exactly the coins used from the user's leaderCoins wallet
      if (coinsToDeduct > 0) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && widget.products.isNotEmpty) {
          final leaderId = widget.products.first.groupLeaderId;
          await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default')
              .collection('user')
              .doc(user.uid)
              .update({
            'leaderCoins.$leaderId': FieldValue.increment(-coinsToDeduct),
          });
        }
      }

      if (widget.fromCart) {
        cartState.clearCart();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Color(0xFF39FF14),
          ),
        );
        Navigator.pop(context); // Return to previous screen
        if (widget.fromCart) {
           Navigator.pop(context); // Close cart too if applicable
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'CHECKOUT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shipping Details',
                style: TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'First Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _wilayaController,
                label: 'Wilaya (State/Province)',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 40),
              
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.products.length} item(s) selected',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),

              // Coin Discount Switch
              if (_availableCoins > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Use my coins for a discount\n(Available: $_availableCoins)',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          Switch(
                            value: _useCoins,
                            activeColor: const Color(0xFF39FF14),
                            onChanged: (value) {
                              setState(() {
                                _useCoins = value;
                                if (value) {
                                  // Auto-fill with max useful coins
                                  double originalTotal = widget.fromCart 
                                      ? cartState.totalPrice 
                                      : widget.products.fold(0.0, (sum, item) => sum + item.price);
                                  int maxUseful = (originalTotal / _coinValue).ceil();
                                  int fillAmount = _availableCoins > maxUseful ? maxUseful : _availableCoins;
                                  _coinsInputController.text = fillAmount.toString();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_useCoins) ...[
                        const Divider(color: Colors.white24),
                        Row(
                          children: [
                            const Text('Amount to use:', style: TextStyle(color: Colors.white70)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _coinsInputController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.white30),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF39FF14)),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF39FF14)),
                                  ),
                                ),
                                onChanged: (value) {
                                  int val = int.tryParse(value) ?? 0;
                                  if (val > _availableCoins) {
                                    _coinsInputController.text = _availableCoins.toString();
                                    _coinsInputController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: _coinsInputController.text.length),
                                    );
                                  }
                                  setState(() {}); // Re-trigger UI to recalculate discount math
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Builder(
                builder: (context) {
                  double originalTotal = widget.fromCart 
                      ? cartState.totalPrice 
                      : widget.products.fold(0.0, (sum, item) => sum + item.price);

                  double finalTotal = originalTotal;
                  if (_useCoins && _availableCoins > 0) {
                    int inputCoins = int.tryParse(_coinsInputController.text) ?? 0;
                    if (inputCoins > _availableCoins) inputCoins = _availableCoins;
                    
                    double discount = inputCoins * _coinValue;
                    if (discount >= originalTotal) {
                      finalTotal = 0;
                    } else {
                      finalTotal = originalTotal - discount;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_useCoins && _availableCoins > 0 && finalTotal < originalTotal) ...[
                        Text(
                          'Subtotal: ${originalTotal.toStringAsFixed(0)} DZD',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Discount: -${(originalTotal - finalTotal).toStringAsFixed(0)} DZD',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Total: ${finalTotal.toStringAsFixed(0)} DZD',
                        style: const TextStyle(
                          color: Color(0xFF39FF14),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : const Text('SUBMIT ORDER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFF39FF14)),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF39FF14)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
