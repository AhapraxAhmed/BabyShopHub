import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/shop_provider.dart';
import '../services/auth_provider.dart';
import '../widgets/animated_loader.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final shop = Provider.of<ShopProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final userEmail = auth.currentUser?.email ?? 'guest.parent@gmail.com';
    final success = await shop.processCheckout(userEmail, _addressController.text.trim());

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Order Placed Successfully', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for shopping at BabyShopHub! An itemized receipt has been sent to your email address.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss Dialog
                  Navigator.of(context).pop(); // Pop back to Home
                },
                child: const Text('Return to Shop'),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shop = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: shop.isLoading
          ? const Center(
              child: AnimatedLoader(
                size: 80,
                message: 'Processing secure payment...',
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  const Text(
                    'Shipping Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter shipping address' : null,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      prefixIcon: Icon(Icons.home_outlined),
                      hintText: '123 Sweet Baby Lane, Nursery City',
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Payment Details (Simulated)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cardNameController,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter name on card';
                      if (val.trim().length < 3) return 'Name is too short';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter card number';
                      final reg = RegExp(r'^\d{16}$');
                      if (!reg.hasMatch(val)) return 'Card number must be exactly 16 digits';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                      hintText: '4000123456789010',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cardExpiryController,
                          keyboardType: TextInputType.datetime,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter expiry';
                            final reg = RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$');
                            if (!reg.hasMatch(val)) return 'Use MM/YY format';
                            
                            final parts = val.split('/');
                            final month = int.parse(parts[0]);
                            final year = int.parse('20' + parts[1]);
                            final now = DateTime.now();
                            if (year < now.year || (year == now.year && month < now.month)) {
                              return 'Expired';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date',
                            hintText: 'MM/YY',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cardCvvController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Enter CVV';
                            final reg = RegExp(r'^\d{3,4}$');
                            if (!reg.hasMatch(val)) return 'Must be 3-4 digits';
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Order Total Summary card
                  Card(
                    color: theme.colorScheme.primary.withOpacity(0.04),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cart Subtotal:', style: TextStyle(fontSize: 14)),
                              Text('\$${shop.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Delivery Shipping:', style: TextStyle(fontSize: 14)),
                              Text('FREE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${shop.cartTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _handlePayment,
                    child: const Text('Authorize Payment'),
                  ),
                ],
              ),
            ),
    );
  }
}
