import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import '../../services/Profiles/office/office_profile_service.dart';
import '../../services/Profiles/office/review_service.dart';
import '../../services/session.dart';

class OfficeProfileScreen extends StatefulWidget {
  final bool isOwner;

  final int officeId;

  const OfficeProfileScreen({
    required this.isOwner,
    required this.officeId,
    super.key,
  });

  @override
  State<OfficeProfileScreen> createState() => _OfficeProfileScreenState();
}

class _OfficeProfileScreenState extends State<OfficeProfileScreen> {
  bool isEditMode = false;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final Logger logger = Logger();

  Map<String, dynamic> formData = {};
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfficeData();
    _fetchReviews();
  }

  Future<void> _fetchOfficeData() async {
    setState(() => isLoading = true);
    try {
      final token = await Session.getToken();
      final data = await OfficeService.getOffice(widget.officeId, token);
      setState(() {
        formData = data;
        isLoading = false;
      });
    } catch (e) {
      logger.e('Error loading office data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to load office data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final token = await Session.getToken();
      final data = await ReviewService.getOfficeReviews(widget.officeId, token);
      setState(() {
        reviews = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      logger.e('Error loading reviews: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _saveChanges() async {
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

    final token = await Session.getToken();
    try {
      await OfficeService.updateOffice(widget.officeId, formData, token);

      if (_profileImage != null) {
        await OfficeService.uploadOfficeImage(
          widget.officeId,
          _profileImage!,
          token,
        );
      }

      setState(() => isEditMode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Office updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchOfficeData(); // تحديث البيانات بعد الحفظ لتعكس التغييرات
      }
    } catch (e) {
      logger.e('Error updating office: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update office',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // --- Helper Method for Building a Single Info Field ---
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
                      // يتعامل مع قيمة null: يعرض 'N/A' إذا كان الحقل اختيارياً و null، وإلا يعرض '-'
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

  // --- Helper Method for Profile Header Section ---
  Widget _buildProfileHeader(ImageProvider profileImage) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.isOwner && isEditMode ? _pickImage : null,
          child: Stack(
            // Use Stack to overlay camera icon
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
              if (widget.isOwner &&
                  isEditMode) // Show camera icon only if owner and in edit mode
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent, // Background color for the icon
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ), // White border for contrast
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
        // Office Name and Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                formData['name'] ?? 'Office Name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (formData['rating'] != null && !isEditMode) ...[
              // Show rating only in view mode
              const SizedBox(width: 8),
              Text(
                formData['rating']?.toStringAsFixed(1) ?? '',
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
            onPressed:
                isEditMode
                    ? _saveChanges
                    : () => setState(() => isEditMode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, // تم تغيير اللون إلى accent
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEditMode ? "Save Changes" : "Edit Profile"),
          ),
        const SizedBox(height: 10),
        const Divider(color: AppColors.shadow, thickness: 1), // خط فاصل رفيع
        const SizedBox(height: 10),

        // المنقولة تحت الصورة مع الأيقونات (لن تعرض التسمية في وضع العرض بفضل showLabelInViewMode: false)
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
          "Office Location",
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

  // --- Helper Method for Office Details Section ---
  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Office Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(color: AppColors.shadow, thickness: 1),
        // هذه الحقول ستعرض التسمية الجديدة والأيقونات في وضع العرض (showLabelInViewMode ستبقى true افتراضياً)
        _buildInfoField(
          "Office Capacity",
          "capacity",
          isNumber: true,
          icon: Icons.people,
        ),
        _buildInfoField(
          "Loyalty Points",
          "points",
          isNumber: true,
          icon: Icons.star_border,
        ),
        _buildInfoField(
          "Staff Members Count",
          "staff_count",
          isNumber: true,
          icon: Icons.groups,
        ),
        _buildInfoField(
          "Active Projects Count",
          "active_projects_count",
          isNumber: true,
          icon: Icons.work,
        ),
        _buildInfoField(
          "Branches List",
          "branches",
          icon: Icons.alt_route,
          isOptional: true,
        ),
      ],
    );
  }

  // --- Helper Method for Reviews Section ---
  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20), // Spacing from previous section
        const Text(
          'Customer Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const Divider(color: AppColors.shadow, thickness: 1),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          const Text(
            'No reviews yet.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          ...reviews.map((r) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              color: AppColors.card,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  r['user']?['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  r['comment'] ?? '',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing:
                    r['rating'] != null
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              r['rating'].toString(),
                              style: const TextStyle(color: AppColors.accent),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ],
                        )
                        : null,
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Office Profile",
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
                    : const AssetImage("assets/office.png"))
                as ImageProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Office Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.accent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              isWeb
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(16),
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
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
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
                              child: _buildDetailsSection(),
                            ),
                            // Hide reviews section when in edit mode
                            if (!isEditMode) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
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
                                child: _buildReviewsSection(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                  : Column(
                    // Mobile Layout
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
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
                        margin: const EdgeInsets.only(bottom: 16),
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
                        child: _buildDetailsSection(),
                      ),
                      // Hide reviews section when in edit mode
                      if (!isEditMode)
                        Container(
                          padding: const EdgeInsets.all(16),
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
                          child: _buildReviewsSection(),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
