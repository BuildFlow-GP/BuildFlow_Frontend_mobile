import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSelectorScreen extends StatefulWidget {
  const MapSelectorScreen({super.key});

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? selectedLocation;

  /// Get coordinates for area name using OpenStreetMap's Nominatim
  Future<LatLng?> getCoordinatesFromArea(String areaName) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$areaName&format=json&limit=1';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  void _searchArea() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final LatLng? result = await getCoordinatesFromArea(query);
    if (result != null) {
      _mapController.move(result, 15);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Area not found.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Land Location')),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for area (e.g. Nablus, رام الله)...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchArea,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchArea(),
            ),
          ),
          // 🗺️ Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(31.9, 35.2),
                initialZoom: 13,
                onTap: (tapPosition, point) {
                  setState(() {
                    selectedLocation = point;
                  });
                },
              ),
              children: [
                // 🧱 Base layer (OSM)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.buildflow',
                ),
                // 🌍 GeoMOLG Layer (if you want)
                TileLayer(
                  urlTemplate:
                      'https://geomolg.ps/arcgis/rest/services/Parcels_RegisteredPalestinian/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.buildflow',
                ),
                // 📍 Marker layer
                if (selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        width: 60,
                        height: 60,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // ✅ Confirm button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed:
                  selectedLocation != null
                      ? () {
                        Navigator.pop(context, selectedLocation);
                      }
                      : null,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}
