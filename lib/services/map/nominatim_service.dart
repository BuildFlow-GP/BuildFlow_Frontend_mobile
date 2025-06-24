import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Get coordinates for area name (Geocoding)
  Future<LatLng?> getCoordinatesFromArea(String areaName) async {
    final url = '$_baseUrl/search?q=$areaName&format=json&limit=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return LatLng(lat, lon);
        }
      }
      print(
        'Nominatim Geocoding failed: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error in Nominatim Geocoding: $e');
    }
    return null;
  }

  /// Get Area Name from Coordinates (Reverse Geocoding)
  Future<String?> getAreaFromCoordinates(LatLng latLng) async {
    // zoom=10 يعطي معلومات عن المنطقة الإدارية، zoom=18 يعطي تفاصيل العنوان
    final url =
        '$_baseUrl/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=10&addressdetails=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['address'] != null) {
          // اختر الحقل الأنسب لتمثيل "المنطقة" في سياق فلسطين
          // 'state' أو 'county' غالباً ما تكون جيدة للمناطق الإدارية الكبيرة
          return data['address']['state'] ??
              data['address']['county'] ??
              data['address']['city'] ??
              data['display_name'];
        }
      }
      print(
        'Nominatim Reverse Geocoding failed: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Error in Nominatim Reverse Geocoding: $e');
    }
    return null;
  }
}
