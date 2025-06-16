import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import '../../services/Profiles/company_profile_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  final bool isOwner;
  final int companyId;

  const CompanyProfileScreen({
    required this.isOwner,
    required this.companyId,
    super.key,
  });

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  bool isEditMode = false;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final Logger logger = Logger();

  Map<String, dynamic> formData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final data = await CompanyService.fetchProfile();
      setState(() {
        formData = data ?? {};
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading company data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load company data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleEdit() async {
    if (isEditMode) {
      if (!_formKey.currentState!.validate()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please fill all required fields',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      _formKey.currentState!.save();
      try {
        bool success = await CompanyService.updateProfile(formData);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Profile updated successfully',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (_profileImage != null) {
            // Placeholder: Implement image upload logic in CompanyService if needed
            // await CompanyService.uploadCompanyImage(widget.companyId, _profileImage!);
            logger.i(
              'Profile image picked but upload function not explicitly shown for CompanyService.',
            );
          }
          _loadProfile();
          setState(() => isEditMode = false);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to update profile',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } catch (e) {
        logger.e('Error updating company profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to update profile',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      setState(() => isEditMode = true);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Widget _buildInfoField(
    String label,
    String field, {
    bool isNumber = false,
    IconData? icon,
    bool isOptional = false,
    bool showLabelInViewMode = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isEditMode
            ? TextFormField(
              initialValue: formData[field]?.toString() ?? '',
              keyboardType:
                  isNumber ? TextInputType.number : TextInputType.text,
              validator:
                  isOptional
                      ? null
                      : (val) =>
                          (val == null || val.isEmpty) ? 'Required' : null,
              onSaved: (val) {
                setState(() {
                  formData[field] =
                      isNumber
                          ? (num.tryParse(val ?? '') ?? (isOptional ? null : 0))
                          : val;
                });
              },
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon:
                    icon != null ? Icon(icon, color: AppColors.accent) : null,
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                  ],
                  if (showLabelInViewMode)
                    Text(
                      '$label: ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      formData[field]?.toString() ?? (isOptional ? 'N/A' : '-'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildProfileHeader(ImageProvider profileImage) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.isOwner && isEditMode ? _pickImage : null,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: profileImage,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                child:
                    formData['profile_image'] == null && _profileImage == null
                        ? Icon(
                          Icons.business,
                          size: 50,
                          color: AppColors.accent,
                        )
                        : null,
              ),
              if (widget.isOwner && isEditMode)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Company Name and Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                formData['name'] ?? 'Company Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (formData['rating'] != null && !isEditMode) ...[
              const SizedBox(width: 8),
              Text(
                formData['rating']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              const Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (widget.isOwner)
          ElevatedButton(
            onPressed: _toggleEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEditMode ? "Save Changes" : "Edit Profile"),
          ),
        const SizedBox(height: 10),
        const Divider(color: AppColors.shadow, thickness: 1),
        const SizedBox(height: 10),

        _buildInfoField(
          "Email Address",
          "email",
          icon: Icons.email,
          showLabelInViewMode: false,
        ),
        _buildInfoField(
          "Phone Number",
          "phone",
          icon: Icons.phone,
          showLabelInViewMode: false,
        ),
        _buildInfoField(
          "Company Location",
          "location",
          icon: Icons.location_on,
          showLabelInViewMode: false,
        ),
        _buildInfoField(
          "Bank Account",
          "bank_account",
          icon: Icons.account_balance,
          showLabelInViewMode: false,
        ),
      ],
    );
  }

  Widget _buildCompanyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Company Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(color: AppColors.shadow, thickness: 1),
        _buildInfoField(
          "Company Description",
          "description",
          icon: Icons.description,
        ),
        _buildInfoField("Company Type", "company_type", icon: Icons.category),
        _buildInfoField(
          "Staff Members Count",
          "staff_count",
          isNumber: true,
          icon: Icons.groups,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // لم نعد بحاجة لـ isWeb لتقسيم التخطيط الرئيسي
    // لكن يمكن الاحتفاظ بها لضبط أحجام عناصر أخرى إذا لزم الأمر

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Company Profile",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final profileImage =
        _profileImage != null
            ? FileImage(_profileImage!)
            : (formData['profile_image'] != null &&
                        formData['profile_image'] != ''
                    ? NetworkImage(formData['profile_image'])
                    : const AssetImage("assets/company.png"))
                as ImageProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Company Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.accent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            // توسيط المحتوى الأفقي بالكامل
            child: ConstrainedBox(
              // تحديد عرض أقصى للمحتوى
              constraints: BoxConstraints(
                maxWidth: 800, // عرض أقصى، يمكنك تعديله حسب الحاجة
              ),
              child: Column(
                // ترتيب البطاقات عمودياً
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch, // لجعل البطاقات تمتد للعرض الأقصى المحدد
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ), // مسافة بين البطاقات
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildProfileHeader(profileImage),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    // لا يوجد margin-bottom هنا إذا كانت هذه آخر بطاقة
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildCompanyDetailsSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
