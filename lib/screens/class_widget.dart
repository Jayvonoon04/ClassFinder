import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClassWidget extends StatelessWidget {
  final DocumentSnapshot classDoc;

  const ClassWidget({super.key, required this.classDoc});

  @override
  Widget build(BuildContext context) {
    final data = classDoc.data() as Map<String, dynamic>;

    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? '';
    final date = data['date'] ?? '';
    final startTime = data['start_time'] ?? '';
    final endTime = data['end_time'] ?? '';
    final imageBase64 = data['image_base64'] ?? '';
    final price = data['price']; // could be int or double

    Image? profileImage;
    try {
      String cleanBase64 = imageBase64.trim();
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      final bytes = base64Decode(cleanBase64);
      profileImage = Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      profileImage = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 90,
              height: 90,
              color: Colors.grey[300],
              child: profileImage ?? Image.asset('assets/placeholder.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  '$date | $startTime - $endTime',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Price: \$${price.toString()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}