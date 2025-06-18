// screens/supervision/select_company_for_supervision_screen.dart
import 'package:buildflow_frontend/models/Basic/company_model.dart'; //  ✅ موديل الشركة
import 'package:buildflow_frontend/services/Basic/suggestion_service.dart'; //  ✅ سيرفس المقترحات (يحتوي على getSuggestedCompanies)
import 'package:buildflow_frontend/themes/app_colors.dart';
import 'package:buildflow_frontend/utils/constants.dart'; //  لـ Constants.baseUrl للصور
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

//  الشاشة التالية: اختيار المكتب المشرف
import '../../services/create/chosen_office_service.dart';
import '../../services/create/project_service.dart';

final logger = Logger();

class SelectCompanyForSupervisionScreen extends StatefulWidget {
  final int projectId; //  نستقبل projectId من الشاشة السابقة

  const SelectCompanyForSupervisionScreen({super.key, required this.projectId});

  @override
  State<SelectCompanyForSupervisionScreen> createState() =>
      _SelectCompanyForSupervisionScreenState();
}

class _SelectCompanyForSupervisionScreenState
    extends State<SelectCompanyForSupervisionScreen> {
  final SuggestionService _suggestionService =
      SuggestionService(); //  استخدام SuggestionService
  List<CompanyModel> _companies = []; //  ✅ قائمة الشركات
  List<CompanyModel> _filteredCompanies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  CompanyModel? _selectedCompany; //  ✅ الشركة المختارة

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final companies =
          await _suggestionService.getSuggestedCompanies(); //  ✅ جلب الشركات
      if (mounted) {
        setState(() {
          _companies = companies;
          _filteredCompanies = companies;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Failed to load companies: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load companies: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredCompanies =
          _companies.where((company) {
            return company.name.toLowerCase().contains(_searchQuery) ||
                (company.location?.toLowerCase().contains(_searchQuery) ??
                    false) ||
                (company.companyType?.toLowerCase().contains(_searchQuery) ??
                    false);
          }).toList();
      if (_selectedCompany != null &&
          !_filteredCompanies.contains(_selectedCompany)) {
        _selectedCompany = null;
      }
    });
  }

  void _onCompanyTapped(CompanyModel company) {
    //  ✅ تعديل النوع هنا
    setState(() {
      _selectedCompany = company;
    });
    logger.i('Tapped company: ${company.name}');
  }

  void _navigateToNextStep({CompanyModel? company}) {
    //  نمرر الشركة المختارة (أو null إذا skip)
    logger.i(
      'Proceeding to select supervising office. Project ID: ${widget.projectId}, Selected Company ID: ${company?.id}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChooseOfficeForSupervisionScreen(
              //  ✅ شاشة اختيار المكتب للإشراف
              projectId: widget.projectId,
              assignedCompanyId: company?.id, //  تمرير companyId (قد يكون null)
            ),
      ),
    );
  }

  Widget _buildCompanyCard(CompanyModel company, double cardWidth) {
    //  ✅ تعديل النوع هنا
    final bool isSelected = _selectedCompany == company;
    //  نفس تصميم كرت المكتب تقريباً، مع تعديلات طفيفة لبيانات الشركة
    return GestureDetector(
      onTap: () => _onCompanyTapped(company),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: cardWidth,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                company.profileImage != null && company.profileImage!.isNotEmpty
                    ? (company.profileImage!.startsWith('http')
                        ? company.profileImage!
                        : '${Constants.baseUrl}/${company.profileImage}')
                    : 'https://via.placeholder.com/80/CCCCCC/FFFFFF?Text=Comp', // صورة افتراضية للشركة
                width: cardWidth * 0.15,
                height: cardWidth * 0.15,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: cardWidth * 0.15,
                      height: cardWidth * 0.15,
                      color: AppColors.background,
                      child: Icon(
                        Icons.business_center_outlined,
                        size: cardWidth * 0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 17 : 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ), // تعديل حجم الخط
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (company.companyType != null &&
                      company.companyType!.isNotEmpty)
                    Text(
                      'Type: ${company.companyType}',
                      style: TextStyle(
                        fontSize: cardWidth > 400 ? 13 : 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (company.location != null && company.location!.isNotEmpty)
                    Text(
                      company.location!,
                      style: TextStyle(
                        fontSize: cardWidth > 400 ? 13 : 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  if (company.rating != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade700,
                          size: 17,
                        ), // تعديل الحجم
                        const SizedBox(width: 5), // تعديل المسافة
                        Text(
                          company.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: cardWidth > 400 ? 13 : 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 28,
              ), // تعديل الحجم
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(
    String message,
    VoidCallback onClearSearch,
    double cardWidth,
  ) {
    //  نفس دالة _buildNoResultsState من ChooseOfficeScreen، مع تعديل النصوص لتناسب الشركات
    return Center(
      /* ... (يمكنكِ نسخها وتعديل النصوص مثل "No companies found") ... */
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.domain_verification_outlined,
              size: 80,
              color: AppColors.primary,
            ), // أيقونة للشركات
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms or refresh the list.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: cardWidth * 0.6,
              child: OutlinedButton(
                onPressed: onClearSearch,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: cardWidth * 0.6,
              child: ElevatedButton(
                onPressed: _loadCompanies, //  ✅ تحديث لاستدعاء _loadCompanies
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Refresh Companies',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          /* ... AppBar مشابه، مع تغيير العنوان إلى "Select Company (Optional)" ... */
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                  "Select Company (Optional)",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  color: AppColors.accent,
                  tooltip: 'Refresh Companies',
                  onPressed: _isLoading ? null : _loadCompanies,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    /* ... نفس حقل البحث، مع تعديل النصوص لـ Company ... */
                    labelText: 'Search Company',
                    hintText: 'Search by name, type, or location',
                    prefixIcon: Icon(Icons.search, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => _onSearchChanged(''),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                          : _filteredCompanies.isEmpty
                          ? _buildNoResultsState(
                            _searchQuery.isNotEmpty
                                ? 'No companies found matching "$_searchQuery"'
                                : 'No companies available.',
                            () => _onSearchChanged(''),
                            cardWidth,
                          )
                          : ListView.builder(
                            itemCount: _filteredCompanies.length,
                            itemBuilder: (context, index) {
                              final company = _filteredCompanies[index];
                              return Center(
                                child: _buildCompanyCard(company, cardWidth),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 16),
                //  ✅✅✅ أزرار Next و Skip ✅✅✅
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        //  زر Skip
                        onPressed:
                            _isLoading
                                ? null
                                : () => _navigateToNextStep(
                                  company: null,
                                ), //  تمرير null للشركة
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(
                            double.infinity,
                            50,
                          ), //  جعل الزر يمتد
                          side: BorderSide(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Skip This Step',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () => _navigateToNextStep(
                                  company: _selectedCompany,
                                ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3, // تقليل الظل
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          _selectedCompany == null
                              ? 'Select Company or Skip'
                              : 'Next with ${(_selectedCompany!.name.length > 10 ? '${_selectedCompany!.name.substring(0, 10)}...' : _selectedCompany!.name)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ), // تصغير الخط قليلاً
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//  ✅✅✅ شاشة اختيار المكتب للإشراف (نسخة معدلة من ChooseOfficeScreen) ✅✅✅
//  screens/supervision/choose_office_for_supervision_screen.dart (اسم مقترح)
class ChooseOfficeForSupervisionScreen extends StatefulWidget {
  final int projectId;
  final int? assignedCompanyId; //  اختياري

  const ChooseOfficeForSupervisionScreen({
    super.key,
    required this.projectId,
    this.assignedCompanyId,
  });

  @override
  State<ChooseOfficeForSupervisionScreen> createState() =>
      _ChooseOfficeForSupervisionScreenState();
}

class _ChooseOfficeForSupervisionScreenState
    extends State<ChooseOfficeForSupervisionScreen> {
  final SuggestionService _suggestionService =
      SuggestionService(); //  استخدام SuggestionService
  final ProjectService _projectService =
      ProjectService(); //  لإرسال طلب الإشراف

  List<Office> _offices =
      []; //  افترض أن Office هو موديل المكتب من chosen_office_service
  List<Office> _filteredOffices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Office? _selectedOffice;
  bool _isSubmittingRequest = false;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    // ... (نفس كود _loadOffices من ChooseOfficeScreen الأصلي، باستخدام SuggestionService.getSuggestedOffices)
    if (mounted) setState(() => _isLoading = true);
    try {
      //  هنا يجب أن تجلبي المكاتب التي يمكنها الإشراف (قد تكون كل المكاتب أو قائمة مقترحة)
      //  سأستخدم getSuggestedOffices كمثال
      final officesFromService = await _suggestionService.getSuggestedOffices();
      //  تحويل OfficeModel إلى Office (إذا كانا مختلفين)
      //  إذا كان OfficeService.fetchSuggestedOffices يرجع List<Office> مباشرة، فهذا أفضل
      //  لنفترض مؤقتاً أن OfficeService.fetchSuggestedOffices يرجع List<Office> (الموديل الذي تستخدمه هذه الشاشة)
      final offices =
          officesFromService
              .map(
                (om) => Office(
                  id: om.id,
                  name: om.name,
                  location: om.location ?? '',
                  rating: om.rating ?? 0.0,
                  imageUrl: om.profileImage ?? '',
                ),
              )
              .toList();

      if (mounted) {
        setState(() {
          _offices = offices;
          _filteredOffices = offices;
          _isLoading = false;
        });
      }
    } catch (e) {
      /* ... معالجة الخطأ ... */
      logger.e('Failed to load offices for supervision: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load offices: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    // ... (نفس كود _onSearchChanged)
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredOffices =
          _offices.where((office) {
            return office.name.toLowerCase().contains(_searchQuery) ||
                office.location.toLowerCase().contains(_searchQuery);
          }).toList();
      if (_selectedOffice != null &&
          !_filteredOffices.contains(_selectedOffice)) {
        _selectedOffice = null;
      }
    });
  }

  void _onOfficeTapped(Office office) {
    // ... (نفس كود _onOfficeTapped)
    setState(() => _selectedOffice = office);
    logger.i('Tapped supervising office: ${office.name}');
  }

  //  ✅✅✅ دالة إرسال طلب الإشراف ✅✅✅
  Future<void> _submitSupervisionRequest() async {
    if (_selectedOffice == null || _isSubmittingRequest) return;

    setState(() => _isSubmittingRequest = true);
    try {
      //  استدعاء دالة السيرفس الجديدة
      await _projectService.requestSupervision(
        projectId: widget.projectId,
        supervisingOfficeId: _selectedOffice!.id,
        assignedCompanyId: widget.assignedCompanyId, //  تمرير companyId
      );

      if (mounted) {
        logger.i(
          'Supervision request sent successfully for project ${widget.projectId} to office ${_selectedOffice!.name}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Supervision request sent to ${_selectedOffice!.name}. Waiting for approval.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        //  العودة للشاشة الرئيسية أو شاشة "مشاريعي"
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      logger.e('Failed to send supervision request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send supervision request: ${e.toString()}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRequest = false);
    }
  }

  // ... (باقي دوال build مثل _buildOfficeCard, _buildNoResultsState, و build method الرئيسي)
  // ...  مع تغيير زر "Next" ليستدعي _submitSupervisionRequest
  // ...  وتغيير عنوان الـ AppBar لـ "Select Supervising Office"

  // (مثال لتعديل زر Next في build method لهذه الشاشة)
  // ElevatedButton(
  //   onPressed: _selectedOffice == null || _isSubmittingRequest ? null : _submitSupervisionRequest,
  //   child: _isSubmittingRequest ? CircularProgressIndicator() : Text('Send Supervision Request'),
  //   // ... (style)
  // )

  //  الـ build method الكامل لهذه الشاشة سيكون مشابهاً جداً لـ ChooseOfficeScreen
  //  مع استبدال _onNextPressed بـ _submitSupervisionRequest في زر الإرسال النهائي
  //  وتغيير العنوان. سأترك لكِ تكييف الـ UI بناءً على ChooseOfficeScreen.
  //  تأكدي من أن _buildOfficeCard هنا تستخدم موديل Office الذي تستخدمه هذه الشاشة.
  Widget _buildOfficeCard(Office office, double cardWidth) {
    /* ... نفس كود بناء كرت المكتب من ChooseOfficeScreen ... */
    final bool isSelected = _selectedOffice == office;
    return GestureDetector(
      onTap: () => _onOfficeTapped(office),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: cardWidth,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(isSelected ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                office.imageUrl.isNotEmpty
                    ? (office.imageUrl.startsWith('http')
                        ? office.imageUrl
                        : '${Constants.baseUrl}/${office.imageUrl}')
                    : 'https://via.placeholder.com/80',
                width: cardWidth * 0.15,
                height: cardWidth * 0.15,
                fit: BoxFit.cover,
                errorBuilder:
                    (c, e, s) => Container(
                      width: cardWidth * 0.15,
                      height: cardWidth * 0.15,
                      color: AppColors.background,
                      child: Icon(
                        Icons.business_rounded,
                        size: cardWidth * 0.1,
                        color: AppColors.textSecondary,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office.name,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    office.location,
                    style: TextStyle(
                      fontSize: cardWidth > 400 ? 14 : 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        office.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: cardWidth > 400 ? 14 : 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(
    String message,
    VoidCallback onClearSearch,
    double cardWidth,
  ) {
    /* ... نفس الكود من ChooseOfficeScreen ... */
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different search terms or refresh the list.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: cardWidth * 0.6,
              child: OutlinedButton(
                onPressed: onClearSearch,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Clear Search',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: cardWidth * 0.6,
              child: ElevatedButton(
                onPressed: _loadOffices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Refresh Offices',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                  "Select Supervising Office",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  color: AppColors.accent,
                  tooltip: 'Refresh Offices',
                  onPressed: _isLoading ? null : _loadOffices,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: 'Search Office',
                    hintText: 'Search by name or location',
                    prefixIcon: Icon(Icons.search, color: AppColors.accent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => _onSearchChanged(''),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          )
                          : _filteredOffices.isEmpty
                          ? _buildNoResultsState(
                            _searchQuery.isNotEmpty
                                ? 'No offices found matching "$_searchQuery"'
                                : 'No offices available.',
                            () => _onSearchChanged(''),
                            cardWidth,
                          )
                          : ListView.builder(
                            itemCount: _filteredOffices.length,
                            itemBuilder: (context, index) {
                              final office = _filteredOffices[index];
                              return Center(
                                child: _buildOfficeCard(office, cardWidth),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      _selectedOffice == null || _isSubmittingRequest
                          ? null
                          : _submitSupervisionRequest,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(cardWidth, 50),
                    backgroundColor:
                        _selectedOffice != null && !_isSubmittingRequest
                            ? AppColors.accent
                            : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.accent.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isSubmittingRequest
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Send Supervision Request',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
