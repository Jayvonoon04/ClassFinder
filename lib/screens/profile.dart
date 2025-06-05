import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({Key? key}) : super(key: key);

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isEditing = false;

  // User info fields
  String? _firstName;
  String? _lastName;
  String? _mobile;
  String? _gender;
  String? _profileImagePath;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _mobileController;
  String? _editedGender;

  File? _profileImageFile;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showError("User not logged in");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstName = data['first_name'] ?? '';
        _lastName = data['last_name'] ?? '';
        _mobile = data['mobile'] ?? '';
        _gender = data['gender'] ?? '';
        _profileImagePath = data['profile_image'] ?? '';

        _firstNameController = TextEditingController(text: _firstName);
        _lastNameController = TextEditingController(text: _lastName);
        _mobileController = TextEditingController(text: _mobile);
        _editedGender = _gender;

        if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
          _profileImageFile = File(_profileImagePath!);
        }
      } else {
        _firstNameController = TextEditingController();
        _lastNameController = TextEditingController();
        _mobileController = TextEditingController();
      }
    } catch (e) {
      _showError("Failed to load profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      _showError("User not logged in");
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'gender': _editedGender ?? '',
        'profile_image': _profileImagePath ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _firstName = _firstNameController.text.trim();
        _lastName = _lastNameController.text.trim();
        _mobile = _mobileController.text.trim();
        _gender = _editedGender;
        _isEditing = false;
      });

      _showSuccess("Profile updated successfully!");
    } catch (e) {
      _showError("Failed to update profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          !_isEditing
              ? IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() => _isEditing = true);
            },
          )
              : IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 24),
        child: _isEditing ? _buildEditForm() : _buildProfileView(),
      ),
    );
  }

  Widget _buildProfileView() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
              child: _profileImageFile == null
                  ? const Icon(Icons.person, size: 60, color: Colors.white70)
                  : null,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 30),
            _buildInfoRow('First Name', _firstName ?? ''),
            _buildInfoRow('Last Name', _lastName ?? ''),
            _buildInfoRow('Mobile Number', _mobile ?? ''),
            _buildInfoRow('Gender', _gender ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(60),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                  child: _profileImageFile == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                      : null,
                  backgroundColor: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(_firstNameController, 'First Name', 'First name is required'),
              _buildTextField(_lastNameController, 'Last Name', 'Last name is required'),
              _buildTextField(_mobileController, 'Mobile Number', 'Mobile number is required', inputType: TextInputType.phone),
              _buildGenderDropdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      String validatorMsg, {
        TextInputType inputType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: (val) => val == null || val.trim().isEmpty ? validatorMsg : null,
        decoration: InputDecoration(
          labelText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    final genders = ['Male', 'Female', 'Other'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: _editedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: genders
            .map((gender) => DropdownMenuItem(
          value: gender,
          child: Text(gender),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _editedGender = value;
          });
        },
        validator: (val) => val == null || val.isEmpty ? 'Please select gender' : null,
      ),
    );
  }
}