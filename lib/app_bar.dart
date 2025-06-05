import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:classfinder_f/screens/notifications.dart';
import 'package:classfinder_f/screens/profile.dart';  // Import ViewProfileScreen
import 'package:classfinder_f/screens/login.dart';    // Import Login screen

Widget CustomAppBar() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 3),
          blurRadius: 8,
        ),
      ],
    ),
    child: Row(
      children: [
        // Logo / Title with gradient text effect
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'ClassFinder',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white, // Will get shader color
              letterSpacing: 1.1,
            ),
          ),
        ),

        const Spacer(),

        // Notifications icon with circular blue background and subtle shadow
        Material(
          color: Colors.blue.shade50,
          shape: const CircleBorder(),
          child: IconButton(
            icon: Icon(Icons.notifications, color: Colors.blue.shade700),
            onPressed: () {
              Get.to(() => UserNotificationScreen());
            },
            splashRadius: 24,
            tooltip: 'Notifications',
          ),
        ),

        SizedBox(width: Get.width * 0.03),

        // Popup menu button with icon and shadow background
        Material(
          color: Colors.blue.shade50,
          shape: const CircleBorder(),
          child: PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Colors.blue.shade700),
            onSelected: (value) async {
              if (value == 'profile') {
                Get.to(() => ViewProfileScreen());
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => Login());
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(Icons.person, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}