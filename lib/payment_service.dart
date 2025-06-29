import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classfinder_f/utils/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Map<String, dynamic>? paymentIntentData;

  /// Main payment entry point, returns true if payment succeeds.
  static Future<bool> makePayment(
      BuildContext context, {
        required String amount,
        required String eventId,
      }) async {
    try {
      paymentIntentData = await _createPaymentIntent(amount, 'MYR');
      if (paymentIntentData == null) {
        throw Exception("Failed to create payment intent");
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData!['client_secret'],
          merchantDisplayName: 'ClassFinder',
          style: ThemeMode.light,
        ),
      );

      return await _displayPaymentSheet(context, eventId);
    } catch (e) {
      debugPrint('Exception during makePayment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: ${e.toString()}")),
      );
      return false;
    }
  }

  /// Displays payment sheet, updates Firestore if successful.
  /// Returns true if payment was successful.
  static Future<bool> _displayPaymentSheet(
      BuildContext context,
      String eventId,
      ) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      final userId = _auth.currentUser!.uid;
      final userEmail = _auth.currentUser!.email ?? '';

      final classSnapshot =
      await _firestore.collection('classes').doc(eventId).get();
      final classData = classSnapshot.data();

      final String classTitle = classData?['title'] ?? 'a class';
      final String imageBase64 = classData?['image_base64'] ?? '';

      /// Update 'joined' array and decrement 'max_entries'
      await _firestore.collection('classes').doc(eventId).set({
        'joined': FieldValue.arrayUnion([userId]),
        'max_entries': FieldValue.increment(-1),
      }, SetOptions(merge: true));

      /// Record booking
      await _firestore.collection('booking').doc(eventId).set({
        'booking': FieldValue.arrayUnion([
          {
            'uid': userId,
            'email': userEmail,
            'tickets': 1,
            'timestamp': Timestamp.now(),
          }
        ])
      }, SetOptions(merge: true));

      /// Add notification
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('myNotifications')
          .add({
        'name': 'Payment Successful',
        'message': 'You successfully booked "$classTitle".',
        'time': Timestamp.now(),
        'image': imageBase64,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful!")),
      );

      paymentIntentData = null;

      return true; // Indicate success
    } on StripeException catch (e) {
      debugPrint('StripeException: $e');
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(content: Text("Payment cancelled")),
      );
      return false;
    } catch (e) {
      debugPrint('PaymentSheet Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed unexpectedly.")),
      );
      return false;
    }
  }

  /// Creates payment intent with Stripe and returns its data
  static Future<Map<String, dynamic>?> _createPaymentIntent(
      String amount,
      String currency,
      ) async {
    try {
      final double amountDouble = double.parse(amount);
      final int amountInCents = (amountDouble * 100).round();

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        body: {
          'amount': amountInCents.toString(),
          'currency': currency,
          'payment_method_types[]': 'card',
        },
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Stripe error: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }
}