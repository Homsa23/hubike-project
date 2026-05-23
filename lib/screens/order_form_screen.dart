import 'package:flutter/material.dart';
import 'product_model.dart';
import 'order_model.dart';
import 'cart_state.dart';

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
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _wilayaController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
    });

    final totalAmount = widget.products.fold(0.0, (sum, item) => sum + item.price);

    final order = OrderModel(
      name: _nameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      wilaya: _wilayaController.text.trim(),
      orderDate: DateTime.now(),
      products: widget.products,
      totalAmount: totalAmount,
    );

    try {
      await order.saveToFirestore();

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
              Text(
                'Total: ${widget.products.fold(0.0, (sum, item) => sum + item.price).toStringAsFixed(0)} DZD',
                style: const TextStyle(
                  color: Color(0xFF39FF14),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
