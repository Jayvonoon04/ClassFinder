import 'package:classfinder_f/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart'; // Add for GetX
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:classfinder_f/utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  Stripe.publishableKey = stripePublishableKey; // from Stripe dashboard
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // Use GetMaterialApp instead of MaterialApp
      title: 'Class Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Login(), // Login screen as the home screen
      debugShowCheckedModeBanner: false,
    );
  }
}