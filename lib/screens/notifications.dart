import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  _UserNotificationScreenState createState() => _UserNotificationScreenState();
}

class _UserNotificationScreenState extends State<UserNotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        color: Colors.grey[200],
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('myNotifications')
              .orderBy('time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<DocumentSnapshot> data = snapshot.data!.docs;

            if (data.isEmpty) {
              return const Center(child: Text("No notifications yet."));
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, i) {
                String name = '';
                String title = '';
                String image = '';
                DateTime date = DateTime.now();

                try {
                  name = data[i].get('name');
                } catch (_) {}

                try {
                  title = data[i].get('message');
                } catch (_) {}

                try {
                  image = data[i].get('image');
                } catch (_) {}

                try {
                  date = data[i].get('time').toDate();
                } catch (_) {}

                return _buildNotificationTile(name, title, date, image);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
      String name, String title, DateTime time, String imageBase64) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.shade100,
              backgroundImage: imageBase64.isNotEmpty
                  ? MemoryImage(base64Decode(imageBase64))
                  : null,
              child: imageBase64.isEmpty
                  ? const Icon(Icons.person, color: Colors.blue, size: 28)
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 65, top: 5),
          child: Text(
            timeAgo.format(time),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const Divider(),
      ],
    );
  }
}