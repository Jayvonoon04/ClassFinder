import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:classfinder_f/utils/app_constants.dart';
import 'class_detail_screen.dart';
import 'package:classfinder_f/screens/self_class_detail.dart';
import 'package:classfinder_f/app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
  Map<String, dynamic>? _quote;

  @override
  void initState() {
    super.initState();
    _loadQuote(); // Load a random quote upon screen initialization
  }

  /// Loads a random quote from API Ninjas
  Future<void> _loadQuote() async {
    final quote = await fetchRandomQuote();
    if (mounted) {
      setState(() {
        _quote = quote;
      });
    }
  }

  /// Fetches a random motivational quote using API Ninjas
  Future<Map<String, dynamic>?> fetchRandomQuote() async {
    const apiUrl = 'https://api.api-ninjas.com/v1/quotes';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'X-Api-Key': apiKey},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty ? data.first : null;
      } else {
        print('Failed to load quote: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching quote: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAppBar(), // Custom top app bar
              const SizedBox(height: 20),

              // Header for Quotes Section
              const Text(
                "Quotes for You",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Displays the fetched quote
              if (_quote != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"${_quote!['quote']}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '- ${_quote!['author']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Booked Classes Section
              _buildSection("Classes You've Booked", _buildBookedClasses()),
              const SizedBox(height: 20),

              // User Created Classes Section
              _buildSection("Your Created Classes", _buildUserCreatedClasses()),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper to display section title with its content
  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }

  /// Displays classes that the user has booked
  Widget _buildBookedClasses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('joined', arrayContains: currentUserId)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final docs = snapshot.data!.docs;
        return _buildHorizontalClassList(docs, isCreatedByUser: false);
      },
    );
  }

  /// Displays classes that the user has created
  Widget _buildUserCreatedClasses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('created_by', isEqualTo: currentUserEmail)
          .snapshots(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return _loadingIndicator();
        final docs = snapshot.data!.docs;
        return _buildHorizontalClassList(docs, isCreatedByUser: true);
      },
    );
  }

  /// Builds horizontal scrolling cards for classes
  Widget _buildHorizontalClassList(List<QueryDocumentSnapshot> docs,
      {required bool isCreatedByUser}) {
    if (docs.isEmpty) {
      return const Text("No classes found.");
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: docs.length,
        itemBuilder: (_, index) {
          final doc = docs[index];
          final data = doc.data() as Map<String, dynamic>;
          final title = data['title'] ?? 'No Title';
          final date = data['date'] ?? '';
          final imageBase64 = data['image_base64'] ?? '';

          Image? image;
          try {
            final cleanBase64 = imageBase64.split(',').last.trim();
            final bytes = base64Decode(cleanBase64);
            image = Image.memory(bytes, fit: BoxFit.cover);
          } catch (_) {
            image = null;
          }

          return GestureDetector(
            onTap: () {
              if (isCreatedByUser) {
                Get.to(() => SelfClassDetailScreen(classDoc: doc));
              } else {
                Get.to(() => ClassDetailScreen(classDoc: doc));
              }
            },
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: image ??
                          Image.asset('assets/placeholder.png', fit: BoxFit.cover),
                    ),
                  ),
                  // Class details
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Loading indicator during Firestore data fetching
  Widget _loadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }
}