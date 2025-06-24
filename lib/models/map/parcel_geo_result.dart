import 'package:latlong2/latlong.dart';

class ParcelGeoResult {
  final List<List<LatLng>> coordinatesPolygon; // نقاط المضلع المحولة لـ LatLng
  final LatLng centerCoordinate; // نقطة مركزية للمضلع (لوضع Marker)
  final Map<String, dynamic>
  properties; // الخصائص الوصفية للقطعة (رقم، حوض، منطقة، إلخ)

  ParcelGeoResult({
    required this.coordinatesPolygon,
    required this.centerCoordinate,
    required this.properties,
  });
}
