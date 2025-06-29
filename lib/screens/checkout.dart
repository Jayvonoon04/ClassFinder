import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classfinder_f/payment_service.dart';
import 'package:classfinder_f/screens/home_screen.dart'; // import HomeScreen for navigation

class Checkout extends StatefulWidget {
  final DocumentSnapshot? eventDoc;

  const Checkout(this.eventDoc, {super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  int selectedRadio = -1; // payment method selection (-1 = none)
  Image? eventImageWidget; // holds decoded event image
  bool isLoading = false; // loading state during payment

  @override
  void initState() {
    super.initState();
    _loadImage(); // decode base64 image on load
  }

  /// Decodes base64 image stored in Firestore to display in checkout card.
  void _loadImage() {
    try {
      final data = widget.eventDoc!.data() as Map<String, dynamic>;
      final base64Image = data['image_base64'] ?? '';
      if (base64Image.isNotEmpty) {
        String cleanBase64 = base64Image.trim();
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        final bytes = base64Decode(cleanBase64);
        setState(() {
          eventImageWidget = Image.memory(bytes, fit: BoxFit.cover);
        });
      } else {
        setState(() {
          eventImageWidget = null;
        });
      }
    } catch (e) {
      setState(() {
        eventImageWidget = null;
      });
    }
  }

  /// Updates payment method selection state.
  void setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });
  }

  /// Reusable styled text widget.
  Widget customText(
      String text, {
        double fontSize = 14,
        FontWeight fontWeight = FontWeight.normal,
        Color color = Colors.black,
      }) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
    );
  }

  /// Promo code text field placeholder (non-functional for now).
  Widget textField({required String hint}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventDoc!;
    final data = event.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? '';
    final date = data['date'] ?? '';
    final startTime = data['start_time'] ?? '';
    final endTime = data['end_time'] ?? '';

    // Parse price safely
    final priceRaw = data['price'];
    double price = 0.0;
    if (priceRaw is int) {
      price = priceRaw.toDouble();
    } else if (priceRaw is double) {
      price = priceRaw;
    } else if (priceRaw is String) {
      price = double.tryParse(priceRaw) ?? 0.0;
    }
    const double fixedFee = 2.0; // App fee
    final double total = price + fixedFee;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ------------------------ Header Section ------------------------
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.close, size: 24),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Checkout',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 28),

              /// ------------------------ Event Card Section ------------------------
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                      child: Container(
                        width: 120,
                        height: 150,
                        color: Colors.grey[200],
                        child: eventImageWidget ?? Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customText(title, fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                            const SizedBox(height: 8),
                            customText(description, fontSize: 14, color: Colors.black54),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                customText(date, fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time_outlined, size: 16, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                customText('$startTime - $endTime', fontSize: 13, color: Colors.black54),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              /// ------------------------ Payment Method Section ------------------------
              customText('Payment Method', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              const SizedBox(height: 16),
              Column(
                children: [
                  paymentOptionRow(Icons.credit_card, 'Credit Card', 0),
                  paymentOptionRow(Icons.phone_iphone, 'Apple Pay', 1),
                  paymentOptionRow(Icons.account_balance_wallet, 'PayPal', 2),
                ],
              ),
              const SizedBox(height: 40),

              /// ------------------------ Promo Code Placeholder ------------------------
              customText('Promo Code', fontWeight: FontWeight.bold, fontSize: 16),
              const SizedBox(height: 12),
              textField(hint: 'Enter promo code'),
              const SizedBox(height: 40),

              /// ------------------------ Total Payment Display ------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customText('Total Payment', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
                  customText('\$${total.toStringAsFixed(2)}',
                      fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green[700]!),
                ],
              ),
              const SizedBox(height: 30),

              /// ------------------------ Make Payment Button ------------------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (selectedRadio == -1 || isLoading)
                      ? null
                      : () async {
                    setState(() => isLoading = true);

                    final priceRaw = data['price'];
                    String priceString = '0';

                    if (priceRaw is int || priceRaw is double) {
                      priceString = priceRaw.toString();
                    } else if (priceRaw is String) {
                      priceString = priceRaw;
                    }

                    final eventId = widget.eventDoc!.id;

                    if (selectedRadio == 0) {
                      // Credit Card → Use Stripe
                      bool success = await PaymentService.makePayment(
                        context,
                        amount: priceString,
                        eventId: eventId,
                      );

                      if (success && context.mounted) {
                        // ✅ Navigate back to HomeScreen after successful payment
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                              (route) => false,
                        );
                      }
                    } else if (selectedRadio == 1) {
                      // Apple Pay → Not configured
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Apple Pay is not configured yet.")),
                      );
                    } else if (selectedRadio == 2) {
                      // PayPal → Not supported
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("PayPal is not supported in this app.")),
                      );
                    }

                    setState(() => isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRadio == -1 || isLoading ? Colors.grey : Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 6,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Make Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a selectable payment option row with icon, label, and radio.
  Widget paymentOptionRow(IconData iconData, String label, int val) {
    final selected = selectedRadio == val;
    return InkWell(
      onTap: () => setSelectedRadio(val),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? Colors.blueAccent : Colors.grey.shade300,
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF448AFF).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Row(
          children: [
            Icon(iconData, color: selected ? Colors.blueAccent : Colors.grey),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.blueAccent : Colors.grey[800],
              ),
            ),
            const Spacer(),
            Radio<int>(
              value: val,
              groupValue: selectedRadio,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                if (val != null) setSelectedRadio(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
