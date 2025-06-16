// services/favorite_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/fav/userfav_model.dart';
import '../session.dart'; // للتوكن
import '../../utils/constants.dart';

// استيراد المودلز الخاصة بالعناصر المفصلة (OfficeModel, CompanyModel, ProjectModel)
// واستيراد السيرفسز الخاصة بها (OfficeService, CompanyService, ProjectService)

import '../ReadonlyProfiles/office_readonly.dart'; // أو اسم السيرفس الصحيح
import '../ReadonlyProfiles/company_readonly.dart';
import '../create/project_service.dart';

class FavoriteService {
  final String _baseUrl = Constants.baseUrl;

  // جلب قائمة المفضلة (الـ IDs والـ Types)
  Future<List<FavoriteItemModel>> getFavorites() async {
    final token = await Session.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final response = await http.get(
      Uri.parse('$_baseUrl/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body
          .map(
            (dynamic item) =>
                FavoriteItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } else {
      print(
        'Failed to load favorites (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to load favorites');
    }
  }

  // إضافة عنصر للمفضلة
  Future<void> addFavorite(int itemId, String itemType) async {
    final token = await Session.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    // التأكد أن itemType هو بالأحرف الصغيرة كما يتوقع الـ backend
    final lcItemType = itemType.toLowerCase();
    final allowedTypes = ['office', 'company', 'project'];
    if (!allowedTypes.contains(lcItemType)) {
      throw Exception('Invalid itemType: $itemType');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/favorites'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'itemId': itemId,
        'itemType': lcItemType,
      }),
    );

    if (response.statusCode == 201) {
      // نجح
      print('Added to favorites: $itemId, $lcItemType');
    } else if (response.statusCode == 409) {
      // موجود مسبقاً
      print('Item already in favorites: $itemId, $lcItemType');
      // يمكنك رمي خطأ معين هنا إذا أردتِ التعامل معه في الـ UI
      // throw Exception('Item already in favorites.');
    } else {
      print(
        'Failed to add to favorites (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to add to favorites.');
    }
  }

  // إزالة عنصر من المفضلة
  Future<void> removeFavorite(int itemId, String itemType) async {
    final token = await Session.getToken();
    if (token == null) throw Exception('Authentication token not found.');

    final lcItemType = itemType.toLowerCase();

    final response = await http.delete(
      // الـ backend يستخدم req.query, لذا يجب أن تكون المعاملات في الـ URL
      Uri.parse('$_baseUrl/favorites?itemId=$itemId&itemType=$lcItemType'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // نجح
      print('Removed from favorites: $itemId, $lcItemType');
    } else {
      print(
        'Failed to remove from favorites (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to remove from favorites.');
    }
  }

  // دالة لجلب التفاصيل الكاملة لعنصر مفضل واحد
  Future<dynamic> getFavoriteItemDetail(int itemId, String itemType) async {
    // يمكنكِ جعل token اختيارياً هنا إذا كانت السيرفسز الفردية تتعامل معه

    switch (itemType.toLowerCase()) {
      case 'office':
        // افترض أن لديك OfficeService.getOffice(id, token: token)
        return OfficeProfileService().getOfficeDetails(itemId);
      case 'company':
        // افترض أن لديك CompanyService.getCompany(id, token: token)
        return CompanyProfileService().getCompanyDetails(itemId);
      case 'project':
        // افترض أن لديك ProjectService.getProject(id, token: token)
        //   return await ProjectService().getProject(itemId, token: token);
        return await ProjectService().getProjectDetails(
          itemId,
        ); //  استدعاء الدالة التي أضفناها

      default:
        throw Exception('Unknown item type: $itemType');
    }
  }
}
