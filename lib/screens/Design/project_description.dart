// screens/ProjectDescriptionScreen.dart
import 'package:buildflow_frontend/screens/Design/app_strings.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../services/create/project_design_service.dart'; //  تأكدي من المسار الصحيح
import '../../models/create/project_design_model.dart';
import 'my_project_details.dart'; //  تأكدي من المسار الصحيح

// import 'project_details_final_screen.dart'; //  أو اسم شاشتك الفعلية

final Logger logger = Logger();

class ProjectDescriptionScreen extends StatefulWidget {
  final int projectId; //  استقبال projectId
  const ProjectDescriptionScreen({super.key, required this.projectId});

  @override
  State<ProjectDescriptionScreen> createState() =>
      _ProjectDescriptionScreenState();
}

class _ProjectDescriptionScreenState extends State<ProjectDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  final ProjectDesignService _projectDesignService = ProjectDesignService();

  // ignore: unused_field
  ProjectDesignModel? _currentDesignData;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  // Form state variables - تبقى كما هي
  int? floorCount;
  final TextEditingController bedroomsController = TextEditingController();
  final TextEditingController bathroomsController = TextEditingController();
  final TextEditingController kitchensController = TextEditingController();
  final TextEditingController balconiesController = TextEditingController();

  final List<String> predefinedSpecialRooms = [
    'Salon',
    'Guest Room',
    'Dining Room',
    'Office',
    'Play Room',
    'Library',
    'Gym',
  ]; //  يمكنك تعديل هذه القائمة
  final Set<String> selectedSpecialRooms = {};

  final List<Map<String, String>> directionalRooms = [];
  final TextEditingController roomNameController = TextEditingController();
  String? selectedDirection;

  String? kitchenType = 'Open'; // قيمة افتراضية
  bool masterHasBathroom = false;

  final TextEditingController generalDescriptionController =
      TextEditingController();
  final TextEditingController interiorDesignController =
      TextEditingController();
  final TextEditingController roomDistributionController =
      TextEditingController();

  // ✅ إضافة حقول نطاق الميزانية ✅
  final TextEditingController budgetMinController = TextEditingController();
  final TextEditingController budgetMaxController = TextEditingController();

  final List<String> directions = [
    'North',
    'South',
    'East',
    'West',
    'North-East',
    'North-West',
    'South-East',
    'South-West',
  ]; //  إضافة المزيد من الاتجاهات

  @override
  void initState() {
    super.initState();
    _loadExistingDesignDetails(); //  ✅ جلب البيانات عند تحميل الشاشة
  }

  Future<void> _loadExistingDesignDetails() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);
    try {
      final designData = await _projectDesignService.getProjectDesignDetails(
        widget.projectId,
      );
      if (designData != null && mounted) {
        _currentDesignData = designData;
        //  ✅ تعبئة حقول النموذج بالبيانات الموجودة
        setState(() {
          floorCount = designData.floorCount;
          bedroomsController.text = designData.bedrooms?.toString() ?? '';
          bathroomsController.text = designData.bathrooms?.toString() ?? '';
          kitchensController.text = designData.kitchens?.toString() ?? '';
          balconiesController.text = designData.balconies?.toString() ?? '';

          selectedSpecialRooms.clear();
          if (designData.specialRooms != null) {
            selectedSpecialRooms.addAll(designData.specialRooms!);
          }

          directionalRooms.clear();
          if (designData.directionalRooms != null) {
            //  افترض أن directionalRooms في الموديل هي Map<String, dynamic>
            //  وأنها مخزنة كـ {"room_name": "direction", ...} أو List<Map<String,String>>
            //  إذا كانت JSONB في DB، الـ API يرجعها كـ Map أو List of Maps
            //  الكود الحالي لـ directionalRooms لديك يتعامل مع List<Map<String, String>>
            //  لذا، إذا كان API يرجعها كذلك، فالأمر مباشر.
            //  إذا كان API يرجع Map، ستحتاجين لتحويلها.
            //  لنفترض أن API يرجعها كـ List<Map<String, String>>
            if (designData.directionalRooms is List) {
              for (var item in (designData.directionalRooms as List)) {
                if (item is Map &&
                    item.containsKey('room') &&
                    item.containsKey('direction')) {
                  directionalRooms.add({
                    'room': item['room'].toString(),
                    'direction': item['direction'].toString(),
                  });
                }
              }
            }
          }

          kitchenType = designData.kitchenType ?? 'Open';
          masterHasBathroom = designData.masterHasBathroom ?? false;
          generalDescriptionController.text =
              designData.generalDescription ?? '';
          interiorDesignController.text = designData.interiorDesign ?? '';
          roomDistributionController.text = designData.roomDistribution ?? '';
          budgetMinController.text = designData.budgetMin?.toString() ?? '';
          budgetMaxController.text = designData.budgetMax?.toString() ?? '';
        });
      }
      logger.i(
        "Existing design details loaded for project ${widget.projectId}",
      );
    } catch (e) {
      logger.e("Error loading existing design details: $e");
      // لا يعتبر خطأ فادح إذا لم يكن هناك تصميم سابق، يمكن للمستخدم البدء من جديد
      //  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load existing design details: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    bedroomsController.dispose();
    bathroomsController.dispose();
    kitchensController.dispose();
    balconiesController.dispose();
    roomNameController.dispose();
    generalDescriptionController.dispose();
    interiorDesignController.dispose();
    roomDistributionController.dispose();
    budgetMinController.dispose(); // ✅
    budgetMaxController.dispose(); // ✅
    super.dispose();
  }

  void addDirectionalRoom() {
    if (roomNameController.text.isNotEmpty && selectedDirection != null) {
      setState(() {
        directionalRooms.add({
          'room': roomNameController.text,
          'direction': selectedDirection!,
        });
        roomNameController.clear();
        selectedDirection = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter room name and select a direction.'),
        ),
      );
    }
  }

  void removeDirectionalRoom(int index) {
    setState(() {
      directionalRooms.removeAt(index);
    });
  }

  Future<void> _submitDesignDetails() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    //  تجميع البيانات في كائن ProjectDesignModel
    final designDataToSave = ProjectDesignModel(
      projectId: widget.projectId, //  مهم جداً للربط
      floorCount: floorCount,
      bedrooms: int.tryParse(bedroomsController.text),
      bathrooms: int.tryParse(bathroomsController.text),
      kitchens: int.tryParse(kitchensController.text),
      balconies: int.tryParse(balconiesController.text),
      specialRooms: selectedSpecialRooms.toList(),
      //  directionalRooms هي List<Map<String, String>>، وهي متوافقة مع JSONB إذا تم تحويلها لـ JSON string
      //  أو إذا كان Sequelize/DB driver يتعامل معها مباشرة.
      //  الـ backend يتوقع JSONB، لذا يمكن إرسالها كما هي.
      directionalRooms:
          directionalRooms.isEmpty
              ? null
              : {
                for (var item in directionalRooms)
                  if (item.containsKey('room') && item.containsKey('direction'))
                    item['room']!: item['direction'],
              },
      kitchenType: kitchenType,
      masterHasBathroom: masterHasBathroom,
      generalDescription: generalDescriptionController.text.trim(),
      interiorDesign: interiorDesignController.text.trim(),
      roomDistribution: roomDistributionController.text.trim(),
      budgetMin: double.tryParse(budgetMinController.text),
      budgetMax: double.tryParse(budgetMaxController.text),
      // id, createdAt, updatedAt سيتم إدارتهم بواسطة الـ backend أو الموديل
    );

    try {
      final savedDesign = await _projectDesignService.saveOrUpdateProjectDesign(
        widget.projectId,
        designDataToSave,
      );
      logger.i(
        "Project design details saved/updated successfully: ${savedDesign.id}",
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Project design details submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        //  ✅✅✅ الانتقال إلى شاشة تفاصيل المشروع النهائية (أو أي شاشة تالية) ✅✅✅
        //  افترض أن لديك شاشة اسمها ProjectFinalDetailsScreen أو ما شابه
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ProjectDetailsViewScreen(projectId: widget.projectId),
          ),
        );
        //  أو العودة للشاشة السابقة أو الهوم
        // Navigator.of(
        //   context,
        // ).pop(true); // إرجاع true للإشارة إلى أن شيئاً ما تم بنجاح
      }
    } catch (e) {
      logger.e("Error submitting project design details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit design details: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoadingData
                      ? const Center(child: CircularProgressIndicator())
                      : _buildFormContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    // ... (نفس الكود)
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
            color: AppColors.accent,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              "Project Design Details", // تم تعديل العنوان
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    // ... (نفس الكود)
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ), // تقليل الـ padding العلوي
      child: Card(
        elevation: 2, // تقليل الظل
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), // تقليل الـ radius
        color: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(16), // تقليل الـ padding الداخلي
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Basic Layout"), // عنوان للقسم الأول
                _buildFloorCountField(),
                const SizedBox(height: 16), // تعديل المسافات
                _buildRoomsCountSection(),

                const SizedBox(height: 20),
                _buildSectionTitle("Room Preferences"), // عنوان جديد
                _buildSpecialRoomsSection(),
                const SizedBox(height: 20),
                _buildDirectionalRoomsSection(),

                const SizedBox(height: 20),
                _buildSectionTitle("Kitchen & Master Suite"), // عنوان جديد
                _buildKitchenTypeField(),
                const SizedBox(height: 16),
                _buildMasterBathroomSwitch(),

                const SizedBox(height: 20),
                _buildSectionTitle(
                  "Budget Estimation",
                ), // ✅ قسم الميزانية الجديد
                _buildBudgetRangeFields(), // ✅ ودجت جديدة لحقول الميزانية

                const SizedBox(height: 20),
                _buildSectionTitle("Project Description"), // عنوان جديد
                _buildDescriptionFields(),

                const SizedBox(height: 24), // تعديل المسافات
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //  ✅ ودجت جديدة لحقول نطاق الميزانية ✅
  Widget _buildBudgetRangeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField(
            'Min Budget',
            budgetMinController,
            prefixText: '${AppStrings.currencySymbol} ', //  إضافة رمز العملة
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNumberField(
            'Max Budget',
            budgetMaxController,
            prefixText: '${AppStrings.currencySymbol} ',
          ),
        ),
      ],
    );
  }

  // ويدجت مساعدة لعناوين الأقسام
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
          fontSize: 17, // حجم خط مناسب للعناوين الفرعية
        ),
      ),
    );
  }

  Widget _buildFloorCountField() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Number of Floors', ...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<int>(
            value: floorCount,
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.accent),
            decoration: InputDecoration(
              labelText: 'Number of Floors', // إضافة label هنا
              labelStyle: TextStyle(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ), // تعديل الحشو
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ), // تعديل حجم الخط
            items:
                [1, 2, 3, 4, 5]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(), // إضافة المزيد من الخيارات
            onChanged:
                _isSubmitting
                    ? null
                    : (val) => setState(() => floorCount = val),
            validator:
                (value) =>
                    value == null
                        ? 'Please select number of floors'
                        : null, // إضافة validator
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsCountSection() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Rooms Count', ...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5, // تعديل النسبة قليلاً
          crossAxisSpacing: 10, // تعديل المسافة
          mainAxisSpacing: 6,
          children: [
            _buildNumberField(
              'Bedrooms',
              bedroomsController,
              readOnly: _isSubmitting,
            ),
            _buildNumberField(
              'Bathrooms',
              bathroomsController,
              readOnly: _isSubmitting,
            ),
            _buildNumberField(
              'Kitchens',
              kitchensController,
              readOnly: _isSubmitting,
            ),
            _buildNumberField(
              'Balconies',
              balconiesController,
              readOnly: _isSubmitting,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialRoomsSection() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Special Rooms', ...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 8),
        Wrap(
          // استخدام Wrap بدلاً من Column مباشر لتوزيع أفضل إذا زادت العناصر
          spacing: 8.0, // مسافة أفقية
          runSpacing: 0.0, // مسافة عمودية
          children:
              predefinedSpecialRooms
                  .map(
                    (room) => SizedBox(
                      // تحديد عرض لكل عنصر checkbox
                      width:
                          (MediaQuery.of(context).size.width / 2) -
                          24, // نصف عرض الشاشة تقريباً مع طرح الـ padding
                      child: Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppColors.primary.withAlpha(
                              (0.2 * 255).round(),
                            ),
                          ),
                        ),
                        child: CheckboxListTile(
                          title: Text(
                            room,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          value: selectedSpecialRooms.contains(room),
                          activeColor: AppColors.accent,
                          checkColor: Colors.white,
                          controlAffinity:
                              ListTileControlAffinity
                                  .leading, // جعل الـ checkbox على اليسار
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ), // تقليل الحشو
                          onChanged:
                              _isSubmitting
                                  ? null
                                  : (val) {
                                    setState(() {
                                      if (val == true) {
                                        selectedSpecialRooms.add(room);
                                      } else {
                                        selectedSpecialRooms.remove(room);
                                      }
                                    });
                                  },
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildDirectionalRoomsSection() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Room Direction Preferences',...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 12),
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.end, // لمحاذاة زر الإضافة بشكل أفضل
          children: [
            Expanded(
              flex: 3, // إعطاء مساحة أكبر لاسم الغرفة
              child: _buildTextFieldInternal(
                'Room Name',
                roomNameController,
                readOnly: _isSubmitting,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedDirection,
                  dropdownColor: Colors.white,
                  icon: Icon(
                    Icons.explore_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ), // تغيير الأيقونة
                  decoration: InputDecoration(
                    labelText: 'Direction',
                    labelStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ), // إزالة الحدود الافتراضية
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ), // حدود عند عدم التركيز
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), // تعديل الحشو
                  ),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  items:
                      directions
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                  onChanged:
                      _isSubmitting
                          ? null
                          : (val) => setState(() => selectedDirection = val),
                  validator:
                      (value) =>
                          value == null && roomNameController.text.isNotEmpty
                              ? 'Select direction'
                              : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              // تحديد حجم زر الإضافة
              height: 48, // نفس ارتفاع الحقول الأخرى تقريباً
              child: ElevatedButton(
                // تغيير إلى ElevatedButton
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero, // إزالة الحشو الافتراضي
                ),
                onPressed: _isSubmitting ? null : addDirectionalRoom,
                child: const Icon(Icons.add_circle_outline_rounded, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (directionalRooms.isNotEmpty)
          ListView.builder(
            // استخدام ListView.builder لعرض القائمة
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: directionalRooms.length,
            itemBuilder: (context, index) {
              var room = directionalRooms[index];
              return Card(
                margin: const EdgeInsets.only(top: 6, bottom: 2),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.primary.withAlpha((0.2 * 255).round()),
                  ),
                ),
                child: ListTile(
                  dense: true, // جعل الـ ListTile أصغر
                  title: Text(
                    '${room['room']} - ${room['direction']}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => removeDirectionalRoom(index),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ), // تقليل الحشو
                ),
              );
            },
          )
        else
          Padding(
            // رسالة إذا كانت القائمة فارغة
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "No room direction preferences added yet.",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildKitchenTypeField() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Kitchen Type', ...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: kitchenType,
            dropdownColor: Colors.white,
            icon: Icon(
              Icons.kitchen_outlined,
              color: AppColors.accent,
              size: 20,
            ), // تغيير الأيقونة
            decoration: InputDecoration(
              labelText: 'Kitchen Type',
              labelStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            items:
                ['Open', 'Closed', 'Semi-Open']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(), // إضافة خيارات
            onChanged:
                _isSubmitting
                    ? null
                    : (val) => setState(() => kitchenType = val),
            validator:
                (value) => value == null ? 'Please select kitchen type' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMasterBathroomSwitch() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.primary.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'Master Bedroom Has Private Bathroom?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ), // تعديل النص والحجم
        value: masterHasBathroom,
        activeColor: AppColors.accent,
        onChanged:
            _isSubmitting
                ? null
                : (val) => setState(() => masterHasBathroom = val),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ), // تعديل الحشو
      ),
    );
  }

  Widget _buildDescriptionFields() {
    // ... (نفس الكود، مع إضافة تعطيل إذا _isSubmitting)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text('Descriptions', ...), // تم استبداله بـ _buildSectionTitle
        // const SizedBox(height: 12),
        _buildTextFieldInternal(
          'General Design Description',
          generalDescriptionController,
          lines: 4,
          readOnly: _isSubmitting,
        ), // زيادة عدد الأسطر
        const SizedBox(height: 12),
        _buildTextFieldInternal(
          'Interior Design Preferences',
          interiorDesignController,
          lines: 4,
          readOnly: _isSubmitting,
        ),
        const SizedBox(height: 12),
        _buildTextFieldInternal(
          'Room Distribution Across Floors',
          roomDistributionController,
          lines: 4,
          readOnly: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    // ... (نفس الكود، مع استدعاء _submitDesignDetails وتغيير النص بناءً على _isSubmitting)
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        //  تغيير إلى ElevatedButton.icon
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isSubmitting
                  ? Colors.grey.shade400
                  : AppColors.accent, // لون مختلف أثناء التحميل
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: _isSubmitting ? 0 : 3,
        ),
        // تعطيل الزر إذا لم يكن النموذج صالحاً أو إذا كان هناك إرسال جارٍ
        onPressed:
            (_formKey.currentState?.validate() ?? false) && !_isSubmitting
                ? _submitDesignDetails
                : null,
        icon:
            _isSubmitting
                ? Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.only(right: 8),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Submit Design Details',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  //  دوال بناء الحقول الداخلية لتوحيد الـ decoration
  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          prefixText: prefixText,
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        validator: (val) {
          if (val == null || val.isEmpty) return 'Required';
          if (int.tryParse(val) == null && double.tryParse(val) == null) {
            return 'Invalid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextFieldInternal(
    String label,
    TextEditingController controller, {
    int lines = 1,
    bool readOnly = false,
  }) {
    // تم تغيير الاسم
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: lines,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ), // تعديل الحشو
        alignLabelWithHint:
            true, // لمحاذاة الـ label بشكل أفضل مع الحقول متعددة الأسطر
      ),
      validator: (val) {
        // إضافة validator أساسي
        if (label.toLowerCase().contains('general') &&
            (val == null || val.isEmpty)) {
          // مثال: جعل الوصف العام مطلوباً
          return 'General description is required';
        }
        return null;
      },
    );
  }
}

// _CustomAppBar يبقى كما هو
// ignore: unused_element
class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.15 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
            color: AppColors.accent,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              "Project Design Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// هذه مجرد placeholder، يجب أن تكون لديك شاشة فعلية لعرض تفاصيل المشروع
// class ProjectFinalDetailsScreen extends StatelessWidget {
//   final int projectId;
//   const ProjectFinalDetailsScreen({super.key, required this.projectId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Project $projectId - Final Details')),
//       body: Center(child: Text('All details for project $projectId submitted and under review!')),
//     );
//   }
// }
