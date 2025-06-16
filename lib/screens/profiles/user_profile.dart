import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:buildflow_frontend/widgets/Navbar/navbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/Profiles/user_profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isOwner;
  const UserProfileScreen({required this.isOwner, super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isEditMode = false;
  File? _profileImage;
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> formData = {};
  String? _password;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await UserService.getUserProfile();
    if (data != null) {
      setState(() => formData = data);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  void _toggleEdit() async {
    if (isEditMode && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_password != null && _password!.trim().isNotEmpty) {
        formData['password'] = _password;
      }

      final success = await UserService.updateUserProfile(formData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Profile updated successfully"
                : "Failed to update profile",
          ),
        ),
      );
    }

    setState(() {
      isEditMode = !isEditMode;
      if (!isEditMode) _password = null;
    });
  }

  Widget _buildField(
    String label,
    String fieldName,
    IconData icon, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          isEditMode && !readOnly
              ? TextFormField(
                initialValue: formData[fieldName]?.toString(),
                onSaved: (val) => formData[fieldName] = val,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: AppColors.accent),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              )
              : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formData[fieldName]?.toString() ?? "-",
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Password",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: "Enter new password",
              filled: true,
              fillColor: Colors.grey.shade200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSaved: (val) => _password = val,
          ),
        ],
      ),
    );
  }

  Widget _buildNameWithLocation() {
    return isEditMode
        ? Column(
          children: [
            TextFormField(
              initialValue: formData['name']?.toString(),
              onSaved: (val) => formData['name'] = val,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Full Name",
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: formData['location']?.toString(),
              onSaved: (val) => formData['location'] = val,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Location",
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: AppColors.accent,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: formData['name'] ?? "User Name"),
                  const TextSpan(
                    text: " | ",
                    style: TextStyle(color: AppColors.accent),
                  ),
                  TextSpan(
                    text: formData['location'] ?? "Location",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.accent.withOpacity(0.8),
            ),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          formData.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Navbar(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 16.0,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: isEditMode ? _pickImage : null,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 60,
                                          backgroundImage:
                                              _profileImage != null
                                                  ? FileImage(_profileImage!)
                                                  : const AssetImage(
                                                        'assets/user.png',
                                                      )
                                                      as ImageProvider,
                                          backgroundColor: AppColors.background,
                                        ),
                                        if (isEditMode)
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: AppColors.accent,
                                            child: const Icon(
                                              Icons.camera_alt,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildNameWithLocation(),
                                  const SizedBox(height: 20),
                                  _buildField(
                                    "Email",
                                    "email",
                                    Icons.email,
                                    readOnly: true,
                                  ),
                                  _buildField("Phone", "phone", Icons.phone),
                                  _buildField(
                                    "ID Number",
                                    "id_number",
                                    Icons.badge,
                                  ),
                                  _buildField(
                                    "Bank Account",
                                    "bank_account",
                                    Icons.account_balance,
                                  ),
                                  if (isEditMode) _buildPasswordField(),
                                  const SizedBox(height: 20),
                                  if (widget.isOwner)
                                    ElevatedButton.icon(
                                      onPressed: _toggleEdit,
                                      icon: Icon(
                                        isEditMode ? Icons.save : Icons.edit,
                                      ),
                                      label: Text(
                                        isEditMode
                                            ? "Save Changes"
                                            : "Edit Profile",
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 28,
                      ),
                      color: AppColors.accent, // لون زر الرجوع من AppColors
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
    );
  }
}
