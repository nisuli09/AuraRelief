import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  User? user;

  bool _isSaving = false;

  File? _imageFile;
  String? _imageUrl;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    loadData();
  }

  Future<void> loadData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _imageUrl = doc['photoUrl'];
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (_imageFile == null || user == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user!.uid}.jpg');

    await ref.putFile(_imageFile!);

    return await ref.getDownloadURL();
  }

  Future<void> updateProfile() async {
    if (user == null) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'name': _nameController.text,
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  final Color _primaryColor = const Color(0xFF4A6FA5);
  final Color _accentColor = const Color(0xFF7B61FF);

  final Color _textColor = const Color(0xFF1E2A38);
  final Color _subtitleColor = const Color(0xFF6B7C93);

  final Color _backgroundColor = const Color.fromARGB(255, 3, 33, 78);
  final Color _cardColor = const Color(0xFFDADFE6);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _cardColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: _accentColor.withValues(alpha: 0.2),
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : null,
                        child:
                            (_imageFile == null &&
                                (_imageUrl == null || _imageUrl!.isEmpty))
                            ? Icon(
                                Icons.camera_alt,
                                size: 30,
                                color: _textColor,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  "Tap to change photo",
                  style: TextStyle(fontSize: 12, color: _subtitleColor),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: _subtitleColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _accentColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : updateProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
