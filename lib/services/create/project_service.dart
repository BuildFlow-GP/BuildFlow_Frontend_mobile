import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/Basic/project_model.dart';
import '../../models/userprojects/project_simplified_model.dart';
import '../session.dart';
import '../../utils/Constants.dart';
import 'package:logger/logger.dart';
import 'package:http_parser/http_parser.dart';
// ignore: depend_on_referenced_packages
import 'package:mime/mime.dart';

import '../../models/userprojects/project_readonly_model.dart';

Map<String, dynamic> _cleanRequestBody(Map<String, dynamic> data) {
  // إنشاء نسخة جديدة من الـ map حتى لا نعدل الـ map الأصلية مباشرة
  final Map<String, dynamic> cleanedData = Map.from(data);

  cleanedData.removeWhere((key, value) {
    if (value == null) return true; // إزالة القيم الـ null
    if (value is String && value.isEmpty) return true; // إزالة النصوص الفارغة

    return false;
  });
  return cleanedData;
}

class ProjectService {
  final String _baseUrl = Constants.baseUrl;
  final Logger logger = Logger();

  Future<List<ProjectModel>> getAssignedOfficeProjects({
    int limit = 20,
    int offset = 0,
  }) async {
    final token = await Session.getToken(); //  التوكن الخاص بالمكتب المسجل
    if (token == null || token.isEmpty) {
      logger.w(
        "getAssignedOfficeProjects: No office token found, throwing exception.",
      );
      throw Exception('Office authentication token not found. Please log in.');
    }

    final String url = '$_baseUrl/me/projects?limit=$limit&offset=$offset';
    logger.i("getAssignedOfficeProjects: Requesting URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i(
        "getAssignedOfficeProjects: Response status: ${response.statusCode}",
      );
      if (response.statusCode != 200) {
        logger.w("getAssignedOfficeProjects: Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        // الـ API يرجع مصفوفة من المشاريع مباشرة (وليس كائن pagination كما في getMyNotifications)
        // إذا كان الـ API يرجع كائن pagination، ستحتاجين لتعديل هذا الجزء
        List<dynamic> body = jsonDecode(response.body);
        return body
            .map(
              (dynamic item) =>
                  ProjectModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 403 قد تعني أن المستخدم ليس مكتباً
        throw Exception(
          'Authentication failed or not authorized (not an office). Please log in again.',
        );
      } else if (response.statusCode == 404) {
        logger.w('Assigned office projects endpoint not found (404): $url');
        throw Exception(
          'Could not find assigned projects. Service might be unavailable (404).',
        );
      } else {
        logger.w(
          'Failed to load assigned office projects (Status: ${response.statusCode}): ${response.body}',
        );
        throw Exception(
          'Failed to load assigned projects. Please try again later.',
        );
      }
    } catch (e) {
      logger.e(
        "getAssignedOfficeProjects: HTTP request FAILED or error during processing: $e",
      );
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        "An unexpected error occurred in getAssignedOfficeProjects: ${e.toString()}",
      );
    }
  }

  Future<List<ProjectsimplifiedModel>> getMyProjects() async {
    logger.i("getMyProjects CALLED");
    final token = await Session.getToken();
    logger.i("Token for getMyProjects: $token");

    if (token == null || token.isEmpty) {
      logger.w("getMyProjects: No token found, throwing exception.");
      throw Exception('Authentication token not found. Please log in.');
    }

    final String url = '$_baseUrl/users/me/projects';
    logger.i("getMyProjects: Requesting URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i("getMyProjects: Response status: ${response.statusCode}");
      if (response.statusCode != 200) {
        logger.w("getMyProjects: Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body
            .map(
              (dynamic item) =>
                  ProjectsimplifiedModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else if (response.statusCode == 404) {
        logger.w('My Projects endpoint not found (404): $url');
        throw Exception(
          'Could not find your projects. The service might be unavailable (404). URL: $url',
        );
      } else {
        logger.w(
          'Failed to load my projects (Status: ${response.statusCode}): ${response.body}',
        );
        throw Exception(
          'Failed to load your projects. Please try again later.',
        );
      }
    } catch (e) {
      logger.e(
        "getMyProjects: HTTP request FAILED or error during processing: $e",
      );
      // أعد رمي الخطأ الأصلي أو خطأ مخصص
      if (e is Exception) {
        rethrow; // أعد رمي الخطأ الأصلي إذا كان Exception
      }
      throw Exception(
        "An unexpected error occurred in getMyProjects: ${e.toString()}",
      );
    }
  }

  Future<ProjectreadonlyModel> getProjectDetails(int projectId) async {
    final token =
        await Session.getToken(); // التوكن قد يكون اختيارياً هنا إذا كانت تفاصيل المشروع عامة
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/projects/$projectId',
      ), // هذا الـ endpoint موجود لديكِ
      headers: {
        'Content-Type': 'application/json',
        // أرسلي التوكن إذا كان الـ backend يتوقعه لعرض تفاصيل معينة أو للتحقق
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ProjectreadonlyModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      throw Exception('Project with ID $projectId not found.');
    } else {
      logger.e(
        'Failed to load project details for ID $projectId (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to load project details for ID $projectId');
    }
  }

  Future<ProjectModel> requestInitialProject({
    // تم تعديل اسم الدالة والبارامترات
    required int officeId,
    required String projectType, // يمكن أن يكون نوع التصميم أو اسم مبدئي
    String? initialDescription,
  }) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/projects/request-initial'), // المسار الجديد
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'office_id': officeId,
        'project_type': projectType,
        if (initialDescription != null && initialDescription.isNotEmpty)
          'initial_description': initialDescription,
      }),
    );

    if (response.statusCode == 201) {
      // تم إنشاء الطلب بنجاح، الـ API يرجع المشروع المبدئي
      return ProjectModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 400) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        'Failed to send project request: ${responseBody['message'] ?? "Invalid data."}',
      );
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Authentication failed. Please log in again.');
    } else if (response.statusCode == 404) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(
        'Failed to send project request: ${responseBody['message'] ?? "Office not found."}',
      );
    } else {
      logger.e(
        'Error in requestInitialProject (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception(
        'An unexpected error occurred while sending your project request.',
      );
    }
  }

  Future<void> respondToProjectRequest(
    int projectId,
    String action, {
    String? rejectionReason,
  }) async {
    final token = await Session.getToken(); // التوكن الخاص بالمكتب
    if (token == null || token.isEmpty) {
      throw Exception('Office authentication token not found.');
    }

    final Map<String, String> body = {'action': action.toLowerCase()};
    if (action.toLowerCase() == 'reject' &&
        rejectionReason != null &&
        rejectionReason.isNotEmpty) {
      body['rejection_reason'] = rejectionReason;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/projects/$projectId/respond'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      logger.i(
        'Project request $projectId action ${action.toLowerCase()} successful.',
      );
      // يمكنكِ تحليل الـ response.body إذا أردتِ استخدام المشروع المحدث
      // final responseData = jsonDecode(response.body);
      // final updatedProject = ProjectModel.fromJson(responseData['project']); // إذا أردتِ إرجاعه
    } else {
      logger.e(
        'Failed to ${action.toLowerCase()} project request $projectId (Status: ${response.statusCode}): ${response.body}',
      );
      String errorMessage = 'Failed to ${action.toLowerCase()} request.';
      try {
        final responseBody = jsonDecode(response.body);
        errorMessage = responseBody['message'] ?? errorMessage;
      } catch (_) {
        // فشل تحليل JSON، استخدم الرسالة الافتراضية
      }
      throw Exception(errorMessage);
    }
  }

  Future<ProjectModel> updateProjectDetails(
    int projectId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    // إزالة المفاتيح ذات القيم null لتجنب إرسالها إذا كان الـ backend لا يتوقعها
    // أو إذا كانت ستسبب خطأ (مثلاً، تحويل null إلى نص فارغ أو ما شابه)
    dataToUpdate.removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );
    // التأكد من أن القيم الرقمية يتم إرسالها كأرقام إذا كانت كذلك في الـ backend
    // (jsonEncode يتعامل مع هذا بشكل جيد عادة)

    logger.i(
      "Updating project $projectId with data: ${jsonEncode(dataToUpdate)}",
    );

    final response = await http.put(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dataToUpdate),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        // إذا لم يرجع الـ API كائن المشروع، قد تحتاج لإعادة جلبه
        // return getProjectDetails(projectId); // أو رمي خطأ
        throw Exception('Project data not returned in update response.');
      }
    } else {
      String errorMessage = 'Failed to update project details.';
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = responseBody['message'] ?? errorMessage;
        if (responseBody['errors'] != null) {
          errorMessage += "\nDetails: ${responseBody['errors'].join(', ')}";
        }
      } catch (_) {}
      logger.e(
        'Error updating project $projectId (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception(errorMessage);
    }
  }

  //هاي حطيتها بس لتغيير الاسم للمشروع من قبل المكتب في صفحة تفاصيل المشروع

  Future<ProjectModel> getbyofficeProjectDetails(int projectId) async {
    final token = await Session.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: _authHeaders(token, includeContentType: true),
    );
    _logResponse("getProjectDetails for $projectId", response);
    if (response.statusCode == 200) {
      //  الـ API يرجع الآن ProjectModel كاملاً مع projectDesign و user و office و company
      return ProjectModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    _handleError(response, "fetch project details for ID $projectId");
  }

  //هاي حطيتها بس لتغيير الاسم للمشروع من قبل المكتب في صفحة تفاصيل المشروع
  Future<ProjectModel> updatebyofficeProjectDetails(
    int projectId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }
    final cleanedData = _cleanRequestBody(dataToUpdate);

    logger.d(
      "Updating project $projectId with data: ${jsonEncode(cleanedData)}",
    );
    final response = await http.put(
      Uri.parse(
        '$_baseUrl/projects/byoffice/$projectId',
      ), //  يستدعي PUT /:id العام
      headers: _authHeaders(token),
      body: jsonEncode(cleanedData),
    );
    _logResponse("updateProjectDetails for $projectId", response);
    if (response.statusCode == 200) {
      final rd = jsonDecode(response.body) as Map<String, dynamic>;
      if (rd.containsKey('project')) {
        return ProjectModel.fromJson(rd['project'] as Map<String, dynamic>);
      }
      throw Exception('Project data not returned in update response.');
    }
    _handleError(response, "update project details");
  }

  Future<ProjectModel> getProjectDetailscreate(int projectId) async {
    final token =
        await Session.getToken(); // التوكن قد يكون اختيارياً هنا إذا كانت تفاصيل المشروع عامة
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/projects/$projectId',
      ), // هذا الـ endpoint موجود لديكِ
      headers: {
        'Content-Type': 'application/json',
        // أرسلي التوكن إذا كان الـ backend يتوقعه لعرض تفاصيل معينة أو للتحقق
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      throw Exception('Project with ID $projectId not found.');
    } else {
      logger.e(
        'Failed to load project details for ID $projectId (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception('Failed to load project details for ID $projectId');
    }
  }

  Future<String?> uploadProjectAgreement(
    int projectId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${Constants.baseUrl}/projects/$projectId/upload-agreement',
      ), // استخدام الـ endpoint الجديد
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'agreementFile', //  اسم الحقل الذي يتوقعه multer
        fileBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'), // اختياري
      ),
    );

    logger.i("Uploading agreement file: $fileName for project $projectId");

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    logger.i("Upload agreement response status: ${response.statusCode}");
    logger.i("Upload agreement response body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // افترض أن الـ API يرجع المسار/الاسم الجديد للملف في حقل 'filePath'
      return responseData['filePath'] as String?;
    } else {
      String errorMessage = 'Failed to upload agreement file.';
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = responseData['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<ProjectModel> submitFinalProjectDetails(
    int projectId, {
    String? finalAgreementFilePathFromUpload,
  }) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    // هذا الـ body اختياري. إذا كان API الرفع يحدث agreement_file مباشرة،
    // وكان API الـ submit-final-details لا يتوقع أي body (فقط يغير الحالة بناءً على projectId)،
    // يمكنكِ إرسال body فارغ.
    // إذا كان submit-final-details يتوقع مسار الملف لتحديثه مرة أخرى (للتأكيد مثلاً)،
    // يمكنكِ إرساله. حالياً، الـ backend route الذي كتبناه لا يستخدم الـ body.
    Map<String, dynamic> body = {};
    // if (finalAgreementFilePathFromUpload != null && finalAgreementFilePathFromUpload.isNotEmpty) {
    //   body['agreement_file'] = finalAgreementFilePathFromUpload; // اسم الحقل كما يتوقعه الـ backend
    // }

    logger.i(
      "Service: Submitting final details for project $projectId. Body (if any): ${jsonEncode(body)}",
    );

    final response = await http.put(
      Uri.parse(
        '${Constants.baseUrl}/projects/$projectId/submit-final-details',
      ), //  الـ Endpoint الجديد
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(
        body,
      ), // أرسلي body فارغ إذا كان الـ API لا يحتاج لبيانات إضافية
    );

    logger.i(
      "Service: Submit final details response status: ${response.statusCode}",
    );
    logger.i("Service: Submit final details response body: ${response.body}");

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          "Project data not found in submit-final-details response.",
        );
      }
    } else {
      String errorMessage = 'Failed to submit final project details.';
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = responseData['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<ProjectModel> getProjectProfile(int projectId) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // إرسال التوكن دائماً
      },
    );

    logger.i(
      "GetProjectProfile for ID $projectId - Status: ${response.statusCode}",
    );
    if (response.statusCode != 200) {
      logger.e("GetProjectProfile Body: ${response.body}");
    }

    if (response.statusCode == 200) {
      return ProjectModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 404) {
      throw Exception('Project with ID $projectId not found.');
    } else if (response.statusCode == 403) {
      throw Exception(
        'Forbidden: You are not authorized to view this project.',
      );
    } else {
      throw Exception('Failed to load project details for ID $projectId');
    }
  }

  Future<ProjectModel> proposePayment(
    int projectId,
    double amount,
    String? notes,
  ) async {
    final token = await Session.getToken(); // توكن المكتب
    if (token == null || token.isEmpty) {
      throw Exception('Office authentication token not found.');
    }

    final Map<String, dynamic> body = {'payment_amount': amount};
    if (notes != null && notes.isNotEmpty) {
      body['payment_notes'] = notes;
    }

    logger.i("Proposing payment for project $projectId: ${jsonEncode(body)}");

    final response = await http.put(
      Uri.parse('$_baseUrl/projects/$projectId/propose-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    logger.i("ProposePayment response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      logger.e("ProposePayment response body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // الـ API يرجع { message: '...', project: { ... } }
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Project data not found in propose payment response.');
      }
    } else {
      String errorMessage = 'Failed to propose payment.';
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = responseData['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Future<ProjectModel> updateProjectProgress(int projectId, int stage) async {
    final token = await Session.getToken(); // توكن المكتب
    if (token == null || token.isEmpty) {
      throw Exception('Office authentication token not found.');
    }

    final Map<String, dynamic> body = {'stage': stage};

    logger.i("Updating project $projectId progress to stage $stage");

    final response = await http.put(
      Uri.parse('$_baseUrl/projects/$projectId/progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    logger.i("Update project progress response status: ${response.statusCode}");
    if (response.statusCode != 200) {
      logger.e("Update project progress response body: ${response.body}");
    }

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Project data not found in update progress response.');
      }
    } else {
      String errorMessage = 'Failed to update project progress.';
      try {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = responseData['message'] ?? errorMessage;
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  Map<String, String> _authHeaders(
    String? token, {
    bool includeContentType = true,
  }) {
    /* ... */
    final headers = <String, String>{};
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _logResponse(String functionName, http.Response response) {
    /* ... */
    logger.d("$functionName - Status: ${response.statusCode}");
    if (response.statusCode != 200 && response.statusCode != 201) {
      logger.e("$functionName - Body: ${response.body}");
    } else {
      logger.i(
        "$functionName - Body (Success): ${response.body.length > 300 ? '${response.body.substring(0, 300)}...' : response.body}",
      ); // زيادة الحد قليلاً
    }
  }

  Never _handleError(http.Response response, String operation) {
    /* ... */
    String errorMessage = 'Failed to $operation.';
    // ... (باقي الكود كما هو)
    if (response.statusCode == 401 || response.statusCode == 403) {
      errorMessage =
          'Authentication/Authorization failed for $operation. Please log in again or check permissions.';
    } else if (response.statusCode == 404) {
      errorMessage = 'Resource not found for $operation.';
    } else {
      try {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage =
            responseBody['message'] ?? responseBody['error'] ?? errorMessage;
        if (responseBody['details'] != null &&
            responseBody['details'] is List) {
          errorMessage +=
              "\nDetails: ${(responseBody['details'] as List).join(', ')}";
        } else if (responseBody['errors'] != null &&
            responseBody['errors'] is List) {
          errorMessage +=
              "\nDetails: ${(responseBody['errors'] as List).map((e) => e is Map ? e['message'] : e.toString()).join(', ')}";
        }
      } catch (_) {}
    }
    throw Exception(errorMessage);
  }

  Future<String?> uploadLicenseFile(
    int projectId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/projects/$projectId/upload-license'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    String? mimeType = lookupMimeType(fileName);
    MediaType? contentType =
        mimeType != null
            ? MediaType.parse(mimeType)
            : MediaType('application', 'octet-stream');

    request.files.add(
      http.MultipartFile.fromBytes(
        'licenseFile',
        fileBytes,
        filename: fileName,
        contentType: contentType,
      ),
    );

    logger.i(
      "Uploading licenseFile: '$fileName' as ${contentType.toString()} for project $projectId",
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    _logResponse("Upload of 'licenseFile'", response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['filePath'] as String?;
    }
    _handleError(response, "upload license file");
  }

  Future<String?> uploadArchitecturalFile(
    int projectId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/projects/$projectId/upload-architectural'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    String? mimeType = lookupMimeType(fileName);
    MediaType? contentType =
        mimeType != null
            ? MediaType.parse(mimeType)
            : MediaType('application', 'octet-stream');

    request.files.add(
      http.MultipartFile.fromBytes(
        'architecturalFile',
        fileBytes,
        filename: fileName,
        contentType: contentType,
      ),
    );

    logger.i(
      "Uploading architecturalFile: '$fileName' as ${contentType.toString()} for project $projectId",
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    _logResponse("Upload of 'architecturalFile'", response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['filePath'] as String?;
    }
    _handleError(response, "upload architectural file");
  }

  Future<String?> uploadFinal2DFile(
    int projectId,
    Uint8List fileBytes,
    String fileName,
  ) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/projects/$projectId/upload-final2d'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    String? mimeType = lookupMimeType(fileName);
    // ignore: unnecessary_null_comparison
    MediaType? contentType =
        mimeType != null
            ? MediaType.parse(mimeType)
            : MediaType('application', 'octet-stream');

    request.files.add(
      http.MultipartFile.fromBytes(
        'final2dFile',
        fileBytes,
        filename: fileName,
        contentType: contentType,
      ),
    );

    logger.i(
      "Uploading final2dFile: '$fileName' as ${contentType.toString()} for project $projectId",
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    _logResponse("Upload of 'final2dFile'", response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['filePath'] as String?;
    }
    _handleError(response, "upload final 2D file");
  }

  Future<ProjectModel> requestSupervision({
    required int projectId,
    required int supervisingOfficeId,
    int? assignedCompanyId, // اختياري
  }) async {
    final token = await Session.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in.');
    }

    final Map<String, dynamic> requestBody = {
      'supervising_office_id': supervisingOfficeId,
      //  لا نرسل assigned_company_id إذا كان null لتجنب إرسال مفتاح بقيمة null
      //  الـ backend route يمكنه التعامل مع هذا إذا كان الحقل allowNull: true
    };
    if (assignedCompanyId != null) {
      requestBody['assigned_company_id'] = assignedCompanyId;
    }

    logger.i(
      "Requesting supervision for project $projectId with data: ${jsonEncode(requestBody)}",
    );

    final response = await http.post(
      //  الـ route هو POST
      Uri.parse('$_baseUrl/projects/$projectId/request-supervision'),
      headers: _authHeaders(
        token,
      ), //  افترض أن _authHeaders موجودة وتضيف Content-Type
      body: jsonEncode(
        _cleanRequestBody(requestBody),
      ), //  استخدام _cleanRequestBody جيد هنا
    );

    _logResponse(
      "requestSupervision for project $projectId",
      response,
    ); //  افترض أن _logResponse موجودة

    if (response.statusCode == 200 || response.statusCode == 201) {
      //  الـ backend قد يرجع 200 إذا كان تحديثاً
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      //  الـ API يرجع { message: '...', project: { ... } }
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Project data not found in supervision request response.',
        );
      }
    }
    //  استخدام _handleError إذا كانت موجودة لتوحيد معالجة الأخطاء
    _handleError(response, "request project supervision");
    //  السطر أعلاه سيرمي Exception، لذا لن يصل الكود لما بعده في حالة الخطأ
    //  احتياطي
  }

  Future<ProjectModel> respondToSupervisionRequest(
    int projectId,
    String action, { // "approve" or "reject"
    String? rejectionReason,
  }) async {
    final token = await Session.getToken(); //  التوكن الخاص بالمكتب
    if (token == null || token.isEmpty) {
      throw Exception('Office authentication token not found.');
    }

    Map<String, dynamic> requestBody = {'action': action.toLowerCase()};
    if (action.toLowerCase() == 'reject' &&
        rejectionReason != null &&
        rejectionReason.isNotEmpty) {
      requestBody['rejection_reason'] = rejectionReason;
    }

    logger.i(
      "Responding to supervision for project $projectId with action: $action, data: ${jsonEncode(requestBody)}",
    );

    final response = await http.put(
      Uri.parse(
        '$_baseUrl/projects/$projectId/respond-supervision',
      ), //  تأكدي أن هذا هو المسار الصحيح
      headers: _authHeaders(token),
      body: jsonEncode(_cleanRequestBody(requestBody)),
    );

    _logResponse("respondToSupervisionRequest for $projectId", response);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseData.containsKey('project')) {
        return ProjectModel.fromJson(
          responseData['project'] as Map<String, dynamic>,
        );
      } else {
        throw Exception('Project data not found in supervision response.');
      }
    }
    _handleError(
      response,
      "respond to supervision request (${action.toLowerCase()})",
    );
  }

  Future<List<ProjectModel>> getMyProjectsu() async {
    logger.i("getMyProjects CALLED");
    final token = await Session.getToken();
    logger.i("Token for getMyProjects: $token");

    if (token == null || token.isEmpty) {
      logger.w("getMyProjects: No token found, throwing exception.");
      throw Exception('Authentication token not found. Please log in.');
    }

    final String url = '$_baseUrl/users/me/projects';
    logger.i("getMyProjects: Requesting URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      logger.i("getMyProjects: Response status: ${response.statusCode}");
      if (response.statusCode != 200) {
        logger.w("getMyProjects: Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body
            .map(
              (dynamic item) =>
                  ProjectModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please log in again.');
      } else if (response.statusCode == 404) {
        logger.w('My Projects endpoint not found (404): $url');
        throw Exception(
          'Could not find your projects. The service might be unavailable (404). URL: $url',
        );
      } else {
        logger.w(
          'Failed to load my projects (Status: ${response.statusCode}): ${response.body}',
        );
        throw Exception(
          'Failed to load your projects. Please try again later.',
        );
      }
    } catch (e) {
      logger.e(
        "getMyProjects: HTTP request FAILED or error during processing: $e",
      );
      // أعد رمي الخطأ الأصلي أو خطأ مخصص
      if (e is Exception) {
        rethrow; // أعد رمي الخطأ الأصلي إذا كان Exception
      }
      throw Exception(
        "An unexpected error occurred in getMyProjects: ${e.toString()}",
      );
    }
  }
}
