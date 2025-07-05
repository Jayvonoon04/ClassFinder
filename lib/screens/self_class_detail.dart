import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Displays details for a class created by the current user,
/// showing instructor info, class info, and a decoded image.
class SelfClassDetailScreen extends StatefulWidget {
  final DocumentSnapshot classDoc;

  const SelfClassDetailScreen({Key? key, required this.classDoc}) : super(key: key);

  @override
  State<SelfClassDetailScreen> createState() => _SelfClassDetailScreenState();
}

class _SelfClassDetailScreenState extends State<SelfClassDetailScreen> {
  Map<String, dynamic>? userData; // Stores instructor data from Firestore
  bool loadingUser = true; // Loading state for instructor data

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch instructor data on initialization
  }

  /// Fetches instructor details from Firestore using the email from classDoc
  Future<void> _fetchUserData() async {
    final data = widget.classDoc.data() as Map<String, dynamic>? ?? {};
    final email = data['created_by'] ?? '';
    if (email.isEmpty) {
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

    // Decode and display class image if available
    Image? classImage;
    try {
      String cleanBase64 = imageBase64.trim();
      if (cleanBase64.contains(',')) cleanBase64 = cleanBase64.split(',').last;
      final bytes = base64Decode(cleanBase64);
      classImage = Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      classImage = null;
    }

    String instructorName = data['created_by'] ?? '';
    Widget profileImageWidget = const CircleAvatar(
      radius: 26,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white),
    );

    // If instructor data is loaded, display their name and profile image
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
            radius: 26,
            backgroundImage: MemoryImage(profileBytes),
          );
        } catch (e) {
          debugPrint('Error decoding profile image: $e');
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar with gradient background
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Class Details',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Class image display
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: classImage ??
                            Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Class title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructor details
                    Row(
                      children: [
                        profileImageWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loadingUser
                                    ? 'Loading instructor...'
                                    : instructorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Instructor',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Date and time information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(date, style: const TextStyle(fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.access_time, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('$startTime - $endTime',
                              style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Price display if available
                    if (price != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Price: \$${price.toString()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Description section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
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