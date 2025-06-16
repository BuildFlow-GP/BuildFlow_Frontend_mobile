// Map<String, dynamic> _cleanRequestBody(Map<String, dynamic> data) {
//   // إنشاء نسخة جديدة من الـ map حتى لا نعدل الـ map الأصلية مباشرة
//   final Map<String, dynamic> cleanedData = Map.from(data);

//   cleanedData.removeWhere((key, value) {
//     if (value == null) return true; // إزالة القيم الـ null
//     if (value is String && value.isEmpty) return true; // إزالة النصوص الفارغة
//     // يمكنكِ إضافة شروط أخرى هنا إذا لزم الأمر
//     // مثلاً، إذا كان لديك list فارغة وتريدين إزالتها:
//     // if (value is List && value.isEmpty) return true;
//     return false;
//   });
//   return cleanedData;
// }
