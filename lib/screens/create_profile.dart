import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:classfinder_f/screens/bottom_navigation_bar.dart';

/// Screen for initial user profile creation after signup.
/// Allows users to upload profile image, enter personal details, and save to Firestore.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final formKey = GlobalKey<FormState>();

  // Controllers for user inputs
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final mobileController = TextEditingController();
  final dobController = TextEditingController();

  int selectedGender = -1; // -1 = not selected, 0 = Male, 1 = Female
  bool isLoading = false;
  File? profileImage;

  /// Opens the image picker for selecting a profile picture from the gallery.
  Future<void> imagePickDialog() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  /// Opens a date picker for selecting date of birth.
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dobController.text = '${picked.day}-${picked.month}-${picked.year}';
    }
  }

  /// Validates inputs, uploads user profile data to Firestore, and navigates to BottomBarView on success.
  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    if (dobController.text.isEmpty) {
      _showError("Date of Birth is required");
      return;
    }

    if (selectedGender == -1) {
      _showError("Please select your gender");
      return;
    }

    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("User not logged in");
        return;
      }

      // Upload user profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'dob': dobController.text.trim(),
        'gender': selectedGender == 0 ? "Male" : "Female",
        'email': user.email,
        'profile_image': profileImage?.path ?? "",
        'created_at': FieldValue.serverTimestamp(),
      });

      _showSuccess("Profile created successfully!");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BottomBarView()),
        );
      }
    } on FirebaseException catch (e) {
      _showError(e.message ?? "Something went wrong");
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Shows a red snackbar with the provided error message.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  /// Shows a green snackbar with the provided success message.
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// Profile image picker with gradient border
                InkWell(
                  onTap: imagePickDialog,
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xff7DDCFB),
                          Color(0xffBC67F2),
                          Color(0xffACF6AF),
                          Color(0xffF95549),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(70),
                      ),
                      child: profileImage == null
                          ? const CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.blue,
                          size: 50,
                        ),
                      )
                          : CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        backgroundImage: FileImage(profileImage!),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Input fields
                _buildTextField(
                  controller: firstNameController,
                  hint: "First Name",
                  validatorMsg: "First name is required",
                ),
                _buildTextField(
                  controller: lastNameController,
                  hint: "Last Name",
                  validatorMsg: "Last name is required",
                ),
                _buildTextField(
                  controller: mobileController,
                  hint: "Mobile Number",
                  inputType: TextInputType.phone,
                  validatorMsg: "Mobile number is required",
                ),

                /// Date of birth picker field
                SizedBox(
                  height: 48,
                  child: TextFormField(
                    controller: dobController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      hintText: "Date Of Birth",
                      suffixIcon: const Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Date of Birth is required"
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                /// Gender selection radio buttons
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text("Male"),
                        value: 0,
                        groupValue: selectedGender,
                        onChanged: (val) {
                          setState(() {
                            selectedGender = val!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text("Female"),
                        value: 1,
                        groupValue: selectedGender,
                        onChanged: (val) {
                          setState(() {
                            selectedGender = val!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Submit button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Save"),
                ),

                const SizedBox(height: 20),

                /// Terms reminder
                const Text(
                  'By signing up, you agree to our terms, Data policy and cookies policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to build consistent rounded text fields with validation.
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String validatorMsg,
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: (value) =>
        value == null || value.trim().isEmpty ? validatorMsg : null,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}