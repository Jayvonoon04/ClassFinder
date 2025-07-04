import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'class_detail_screen.dart';

/// Displays all upcoming classes created by other users (not the current user).
/// Pulls data live from Firestore, filtering for upcoming classes.
class Classes extends StatefulWidget {
  const Classes({super.key});

  @override
  State<Classes> createState() => _ClassesState();
}

class _ClassesState extends State<Classes> {
  String currentUserEmail = ''; // Stores current user's email
  final Map<String, String> _emailNameCache = {}; // Cache email -> full name for instructors

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email ?? '';
    }
  }

  /// Retrieves the full name of a user by their email.
  /// Uses Firestore and caches results for efficiency.
  Future<String> _getUserName(String email) async {
    if (_emailNameCache.containsKey(email)) {
      return _emailNameCache[email]!;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    String fullName = email; // fallback to email if user not found

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final firstName = data['first_name'] ?? '';
      final lastName = data['last_name'] ?? '';
      fullName = '$firstName $lastName'.trim();
    }

    _emailNameCache[email] = fullName;
    return fullName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "All Classes",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator while fetching data
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong 😞"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No classes available 📭"));
          }

          // Filter out:
          // - classes created by current user
          // - past classes
          final classDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['created_by'] == currentUserEmail) return false;

            final dateStr = data['date'] ?? '';
            try {
              final classDate = DateFormat('d-M-yyyy').parse(dateStr);
              final today = DateTime.now();
              return !classDate.isBefore(
                DateTime(today.year, today.month, today.day),
              );
            } catch (_) {
              return false; // skip invalid dates
            }
          }).toList();

          if (classDocs.isEmpty) {
            return const Center(child: Text("No upcoming classes for you 😅"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classDocs.length,
            itemBuilder: (context, index) {
              final doc = classDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled Class';
              final description = data['description'] ?? '';
              final date = data['date'] ?? '';
              final startTime = data['start_time'] ?? '';
              final endTime = data['end_time'] ?? '';
              final createdByEmail = data['created_by'] ?? '';
              final imageBase64 = data['image_base64'] ?? '';

              // Decode base64 class image if available
              ImageProvider? imageProvider;
              if (imageBase64.isNotEmpty) {
                try {
                  final imageBytes = base64Decode(imageBase64);
                  imageProvider = MemoryImage(imageBytes);
                } catch (e) {
                  imageProvider = null; // fallback to no image on error
                }
              }

              // Get instructor name asynchronously using FutureBuilder
              return FutureBuilder<String>(
                future: _getUserName(createdByEmail),
                builder: (context, snapshotName) {
                  final createdByName = snapshotName.data ?? createdByEmail;

                  return GestureDetector(
                    onTap: () {
                      // Navigate to ClassDetailScreen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassDetailScreen(classDoc: doc),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display class image if available
                          if (imageProvider != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image(
                                image: imageProvider,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Class title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Description (max 2 lines)
                                Text(
                                  description,
                                  style: const TextStyle(color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Date
                                Row(
                                  children: [
                                    const Icon(Icons.date_range, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(date, style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Time
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$startTime - $endTime',
                                      style: const TextStyle(color: Colors.black54),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Instructor name
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(createdByName, style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}