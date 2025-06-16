import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/Basic/office_model.dart'; // تأكدي من المسار الصحيح
import '../../models/Basic/company_model.dart'; // تأكدي من المسار الصحيح
import '../../models/Basic/project_model.dart'; // تأكدي من المسار الصحيح
import '../../../utils/constants.dart'; // تأكدي من وجود هذا الملف في المسار الصحيح

class SuggestionService {
  static const String _baseUrl = Constants.baseUrl;

  // دالة لجلب المكاتب المقترحة
  Future<List<OfficeModel>> getSuggestedOffices() async {
    final response = await http.get(Uri.parse('$_baseUrl/offices/suggestions'));

    if (response.statusCode == 200) {
      // الـ API يرجع كائن يحتوي على مفتاح "offices" وقيمته مصفوفة
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> officesJson = data['offices'];
      return officesJson.map((json) => OfficeModel.fromJson(json)).toList();
    } else {
      // يمكنك إضافة معالجة أخطاء أفضل هنا (e.g., logging, custom exceptions)
      throw Exception(
        'Failed to load suggested offices (Status Code: ${response.statusCode})',
      );
    }
  }

  // دالة لجلب الشركات المقترحة
  Future<List<CompanyModel>> getSuggestedCompanies() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/companies/suggestions'),
    );

    if (response.statusCode == 200) {
      // الـ API يرجع كائن يحتوي على مفتاح "companies" وقيمته مصفوفة
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> companiesJson = data['companies'];
      return companiesJson.map((json) => CompanyModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load suggested companies (Status Code: ${response.statusCode})',
      );
    }
  }

  // دالة لجلب المشاريع المقترحة
  Future<List<ProjectModel>> getSuggestedProjects() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/projects/suggestions'),
    );

    if (response.statusCode == 200) {
      // الـ API يرجع مصفوفة مباشرة
      List<dynamic> projectsJson = json.decode(response.body);
      return projectsJson.map((json) => ProjectModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load suggested projects (Status Code: ${response.statusCode})',
      );
    }
  }
}
