import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreateClass extends StatefulWidget {
  const CreateClass({super.key});

  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  File? selectedImage;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = '${picked.day}-${picked.month}-${picked.year}';
    }
  }

  Future<void> _pickTime({required TextEditingController controller}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  TimeOfDay? _parseTime(String formattedTime) {
    try {
      final time = TimeOfDay.fromDateTime(
        DateFormat.jm().parse(formattedTime),
      );
      return time;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitClass() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        dateController.text.trim().isEmpty ||
        startTimeController.text.trim().isEmpty ||
        endTimeController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        selectedImage == null) {
      _showError("All fields including image and price are required");
      return;
    }

    double? price;
    try {
      price = double.parse(priceController.text.trim());
      if (price < 0) {
        _showError("Price must be a positive number");
        return;
      }
    } catch (_) {
      _showError("Invalid price format");
      return;
    }

    try {
      final startTime = TimeOfDay(
        hour: int.parse(startTimeController.text.split(":")[0]),
        minute: int.parse(startTimeController.text.split(":")[1].split(' ')[0]),
      );

      final endTime = TimeOfDay(
        hour: int.parse(endTimeController.text.split(":")[0]),
        minute: int.parse(endTimeController.text.split(":")[1].split(' ')[0]),
      );

      if (startTime.hour > endTime.hour ||
          (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
        _showError("End time must be after start time");
        return;
      }
    } catch (e) {
      _showError("Invalid time format. Please reselect start and end times.");
      return;
    }

    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("User not logged in");
        return;
      }

      final imageBytes = await selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance.collection('classes').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'date': dateController.text.trim(),
        'start_time': startTimeController.text.trim(),
        'end_time': endTimeController.text.trim(),
        'image_base64': base64Image,
        'created_by': user.email,
        'created_at': Timestamp.now(),
        'price': price,
      });

      _showSuccess("Class created successfully!");

      titleController.clear();
      descriptionController.clear();
      dateController.clear();
      startTimeController.clear();
      endTimeController.clear();
      priceController.clear();
      setState(() => selectedImage = null);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Class'),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Title"),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Enter class title',
                border: OutlineInputBorder(),
              ),
            ),
            spacing,
            _buildLabel("Description"),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter class description',
                border: OutlineInputBorder(),
              ),
            ),
            spacing,
            _buildLabel("Date"),
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                hintText: 'Pick a date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            spacing,
            _buildLabel("Start Time"),
            TextField(
              controller: startTimeController,
              readOnly: true,
              onTap: () => _pickTime(controller: startTimeController),
              decoration: const InputDecoration(
                hintText: 'Pick start time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
            ),
            spacing,
            _buildLabel("End Time"),
            TextField(
              controller: endTimeController,
              readOnly: true,
              onTap: () => _pickTime(controller: endTimeController),
              decoration: const InputDecoration(
                hintText: 'Pick end time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time_filled),
              ),
            ),
            spacing,
            _buildLabel("Price"),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Enter price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            spacing,
            _buildLabel("Class Image"),
            const SizedBox(height: 8),
            DottedBorder(
              color: Colors.grey,
              dashPattern: [8, 4],
              strokeWidth: 1,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: selectedImage == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitClass,
                icon: const Icon(Icons.check),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
