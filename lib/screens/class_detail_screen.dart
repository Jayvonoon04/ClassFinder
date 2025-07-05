import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'checkout.dart';

/// Displays detailed information for a single class,
/// including image, instructor, description, date/time, and price,
/// with the ability to proceed to checkout.
class ClassDetailScreen extends StatefulWidget {
  final DocumentSnapshot classDoc;

  const ClassDetailScreen({Key? key, required this.classDoc}) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  Map<String, dynamic>? userData; // Holds instructor's user data
  bool loadingUser = true; // Indicates if instructor data is being loaded

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch instructor details on initialization
  }

  /// Fetches instructor user data from Firestore based on the `created_by` email
  Future<void> _fetchUserData() async {
    final data = widget.classDoc.data() as Map<String, dynamic>? ?? {};
    final email = data['created_by'] ?? '';
    if (email.isEmpty) {
      // No instructor email available
      setState(() {
        loadingUser = false;
      });
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        // Instructor found, store user data
        setState(() {
          userData = query.docs.first.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          loadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.classDoc.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? '';
    final date = data['date'] ?? '';
    final startTime = data['start_time'] ?? '';
    final endTime = data['end_time'] ?? '';
    final price = data['price'];
    final imageBase64 = data['image_base64'] ?? '';

    /// Decode base64 image for class preview
    Image? classImage;
    try {
      String cleanBase64 = imageBase64.trim();
      if (cleanBase64.contains(',')) cleanBase64 = cleanBase64.split(',').last;
      final bytes = base64Decode(cleanBase64);
      classImage = Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      classImage = null; // Use placeholder if decoding fails
    }

    /// Setup instructor display name and profile picture
    String instructorName = data['created_by'] ?? '';
    Widget profileImageWidget = const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white, size: 30),
    );

    if (!loadingUser && userData != null) {
      final firstName = userData!['first_name'] ?? '';
      final lastName = userData!['last_name'] ?? '';
      instructorName = ('$firstName $lastName').trim();

      final profileBase64 = userData!['profile_image'] ?? '';
      if (profileBase64.isNotEmpty) {
        try {
          String cleanBase64 = profileBase64.trim();
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          final profileBytes = base64Decode(cleanBase64);
          profileImageWidget = CircleAvatar(
            radius: 28,
            backgroundImage: MemoryImage(profileBytes),
          );
        } catch (e) {
          debugPrint('Error decoding profile image: $e');
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Bar with back button and title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Class Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            /// Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Class image with rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: classImage ??
                            Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Class title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Instructor info with profile image
                    Row(
                      children: [
                        profileImageWidget,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            loadingUser
                                ? 'Loading instructor...'
                                : 'Created by $instructorName',
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Description with styled container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// Date & time display with icons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          /// Date
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 30),

                          /// Time
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 20, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                '$startTime - $endTime',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// Price tag
                    if (price != null) ...[
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_money, size: 22, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              price.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 50),

                    /// Join Class button navigates to Checkout screen
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          backgroundColor: Colors.blueAccent,
                          shadowColor: Colors.blueAccent.withOpacity(0.6),
                        ),
                        onPressed: () {
                          Get.to(() => Checkout(widget.classDoc));
                        },
                        child: const Text(
                          'Join Class',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}