import 'package:latlong2/latlong.dart';

class MapData {
  final String regionName;
  final int? localityId; // ⭐️⭐️⭐️ جديد: معرف المنطقة ⭐️⭐️⭐️
  final String plotNumber;
  final String basinNumber; // هذا هو الرقم النصي للحوض
  final int? blockId; // ⭐️⭐️⭐️ جديد: معرف الحوض ⭐️⭐️⭐️
  final LatLng? coordinates;

  MapData({
    required this.regionName,
    this.localityId, // أضيفي
    required this.plotNumber,
    required this.basinNumber,
    this.blockId, // أضيفي
    this.coordinates,
  });

  MapData copyWith({
    String? regionName,
    int? localityId,
    String? plotNumber,
    String? basinNumber,
    int? blockId,
    LatLng? coordinates,
  }) {
    return MapData(
      regionName: regionName ?? this.regionName,
      localityId: localityId ?? this.localityId,
      plotNumber: plotNumber ?? this.plotNumber,
      basinNumber: basinNumber ?? this.basinNumber,
      blockId: blockId ?? this.blockId,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}
