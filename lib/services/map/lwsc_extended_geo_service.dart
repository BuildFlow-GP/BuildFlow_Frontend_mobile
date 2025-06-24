import 'package:buildflow_frontend/models/map/parcel_geo_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:proj4dart/proj4dart.dart' as proj4;

// ⭐️⭐️⭐️ استيراد الموديل الجديد ⭐️⭐️⭐️

class LWSCExtendedGeoService {
  static const String _baseUrl = 'https://geo.lwsc.ps/api/services/app';

  // ⭐️⭐️⭐️ تعريف أنظمة الإحداثيات (ثابتة - تضع مرة واحدة) ⭐️⭐️⭐️
  // هذا تعريف لنظام الإحداثيات الفلسطيني EPSG:28191
  // تأكدي من صحة هذه البارامترات من مصدر موثوق إذا أمكن
  static final proj4.Projection _p28191 = proj4.Projection.parse(
    '+proj=tmerc +lat_0=31.73333333333333 +lon_0=35.21666666666667 +k=1.000000 +x_0=170000 +y_0=120000 +ellps=GRS80 +towgs84=-256.3,1.3,74.9,-0.69,1.72,2.2,4.6 +units=m +no_defs',
  );
  static final proj4.Projection _p4326 = proj4.Projection.parse(
    'EPSG:4326',
  ); // WGS84 Lat/Lon

  // 1. جلب قائمة المناطق (Localities)
  Future<Map<String, int>> getLocalities() async {
    final uri = Uri.parse('$_baseUrl/Lookup/GetLocalities');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, int> localities = {};
        if (data['result'] != null && data['result'] is List) {
          for (var item in data['result']) {
            localities[item['name'].toString()] = item['id'] as int;
          }
        }
        return localities;
      } else {
        throw Exception('Failed to load localities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading localities: $e');
      throw Exception(
        'Network error or unexpected issue when fetching localities: $e',
      );
    }
  }

  // 2. جلب قائمة الأحواض (Blocks) بناءً على LocalityId
  Future<Map<String, int>> getBlocksByLocalityId(int localityId) async {
    final uri = Uri.parse(
      '$_baseUrl/Lookup/GetBlocksByLocalityId?LocalityId=$localityId',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, int> blocks = {};
        if (data['result'] != null && data['result'] is List) {
          for (var item in data['result']) {
            blocks[item['name'].toString()] = item['id'] as int;
          }
        }
        return blocks;
      } else {
        throw Exception('Failed to load blocks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading blocks: $e');
      throw Exception(
        'Network error or unexpected issue when fetching blocks: $e',
      );
    }
  }

  // 3. جلب بيانات القطعة والإحداثيات بناءً على رقم القطعة و BlockId
  // ⭐️⭐️⭐️ هذه الدالة ستعيد ParcelGeoResult ⭐️⭐️⭐️
  Future<ParcelGeoResult?> getParcelDetailsAndGeometry(
    String parcelNumber,
    int blockId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/Parcels/GetParcelsByParcelNumber?ParcelNumber=$parcelNumber&BlockId=$blockId',
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['result'] != null &&
            data['result']['features'] != null &&
            data['result']['features'].isNotEmpty) {
          final feature =
              data['result']['features'][0]; // افترض أننا نأخذ أول قطعة
          final geometry = feature['geometry'];
          final properties = feature['properties']; // خصائص القطعة

          List<List<LatLng>> transformedPolygon = [];
          LatLng? centerPoint;

          // ⭐️⭐️⭐️ استخراج وتحويل الإحداثيات من MultiPolygon ⭐️⭐️⭐️
          if (geometry['type'] == 'MultiPolygon' &&
              geometry['coordinates'] != null) {
            final List<dynamic> multiPolygonCoordinates =
                geometry['coordinates'];
            double sumLat = 0;
            double sumLon = 0;
            int pointCount = 0;

            for (var polygon in multiPolygonCoordinates) {
              List<LatLng> currentPolygonRing = []; // حلقة واحدة من نقاط المضلع
              for (var ring in polygon) {
                // MultiPolygon يمكن أن يحتوي على عدة مضلعات
                for (var pointCoords in ring) {
                  final double x_28191 = pointCoords[0];
                  final double y_28191 = pointCoords[1];

                  final proj4.Point p28191 = proj4.Point(
                    x: x_28191,
                    y: y_28191,
                  );
                  final proj4.Point p4326 = _p28191.transform(_p4326, p28191);

                  currentPolygonRing.add(LatLng(p4326.y!, p4326.x!));
                  sumLat += p4326.y!;
                  sumLon += p4326.x!;
                  pointCount++;
                }
              }
              transformedPolygon.add(currentPolygonRing);
            }
            if (pointCount > 0) {
              centerPoint = LatLng(sumLat / pointCount, sumLon / pointCount);
            }
          }
          // يمكنك إضافة التعامل مع أنواع هندسة أخرى إذا كانت محتملة (Polygon, Point)

          return ParcelGeoResult(
            coordinatesPolygon: transformedPolygon,
            centerCoordinate:
                centerPoint ?? LatLng(0, 0), // تأكيد أن CenterPoint ليس null
            properties: properties,
          );
        }
      } else {
        throw Exception('Failed to load parcel data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching parcel details and geometry: $e');
      throw Exception(
        'Network error or unexpected issue when fetching parcel: $e',
      );
    }
    return null;
  }
}
