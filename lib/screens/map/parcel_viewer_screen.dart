import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:buildflow_frontend/models/map/parcel_geo_result.dart';
import 'package:buildflow_frontend/services/map/lwsc_extended_geo_service.dart';
import 'package:buildflow_frontend/services/map/nominatim_service.dart';
import 'package:buildflow_frontend/themes/app_colors.dart';

class ParcelViewerScreen extends StatefulWidget {
  const ParcelViewerScreen({super.key});

  @override
  State<ParcelViewerScreen> createState() => _ParcelViewerScreenState();
}

class _ParcelViewerScreenState extends State<ParcelViewerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _parcelController = TextEditingController();

  final TextEditingController _genericSearchController =
      TextEditingController();

  // This service is kept for other functions like getParcelDetailsAndGeometry
  final LWSCExtendedGeoService _lwscGeoService = LWSCExtendedGeoService();
  final NominatimService _nominatimService = NominatimService();

  Map<String, int> _localities = {};
  Map<String, int> _blocks = {};

  String? _selectedLocalityName;
  int? _selectedLocalityId;
  String? _selectedBasinName;
  int? _selectedBlockId;

  List<List<LatLng>>? _parcelPolygonCoordinates;
  LatLng? _parcelCenter;

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  // ignore: unused_field
  bool _isLoadingRoute = false;
  bool _isSearchingParcel = false;

  bool _isLoadingLocalities = false;
  bool _hasLocalitiesError = false;
  bool _isLoadingBlocks = false;
  bool _hasBlocksError = false;

  bool _isManualSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _fetchLocalities();
    _getCurrentUserLocation();
  }

  @override
  void dispose() {
    _parcelController.dispose();
    _genericSearchController.dispose();
    super.dispose();
  }

  // This function fetches localities directly. It is already correct for the new data.
  Future<void> _fetchLocalities() async {
    setState(() {
      _isLoadingLocalities = true;
      _hasLocalitiesError = false;
    });

    const String apiUrl =
        'https://geo.lwsc.ps/api/services/app/Lookup/GetLocalities';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['result'] != null) {
          final List<dynamic> localitiesList = data['result'];
          final Map<String, int> fetchedLocalities = {
            for (var locality in localitiesList)
              (locality['name'] as String): (locality['id'] as int),
          };

          setState(() {
            _localities = fetchedLocalities;
            _isLoadingLocalities = false;
          });
          print(
            'DEBUG: Fetched localities successfully: ${_localities.length} items.',
          );
        } else {
          throw Exception(
            'API returned success=false. Error: ${data['error']}',
          );
        }
      } else {
        throw Exception(
          'Failed to load localities. Status Code: ${response.statusCode}',
        );
      }
    } catch (e, stacktrace) {
      setState(() {
        _isLoadingLocalities = false;
        _hasLocalitiesError = true;
      });
      _showSnackBar('Error fetching regions. Automatic search disabled.');
      print(
        '==================== FETCH LOCALITIES FAILED ====================',
      );
      print('ERROR: $e');
      print('STACKTRACE: \n$stacktrace');
      print(
        '=================================================================',
      );
    }
  }

  // ⭐️⭐️⭐️ START OF MODIFICATION / بداية التعديل ⭐️⭐️⭐️
  // This function is now updated to fetch blocks directly from an API.
  // تم تحديث هذه الدالة لجلب بيانات الأحواض (Basins) مباشرة من الـ API
  Future<void> _fetchBlocks(int localityId) async {
    setState(() {
      _isLoadingBlocks = true;
      _hasBlocksError = false;
      _blocks = {}; // Clear previous blocks
      _selectedBasinName = null;
      _selectedBlockId = null;
    });

    // ⚠️⚠️⚠️ انتبه: هذا الرابط هو تخمين. يرجى التأكد من الرابط الصحيح واستبداله إذا لزم الأمر.
    // ⚠️⚠️⚠️ ATTENTION: This URL is a guess based on the localities URL. Please verify and replace it with the correct one.
    final String apiUrl =
        'https://geo.lwsc.ps/api/services/app/Lookup/GetBlocksByLocalityId?localityId=$localityId';

    print('DEBUG: Fetching blocks from URL: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['result'] != null) {
          final List<dynamic> blocksList = data['result'];

          // The logic is the same: create a Map from 'name' and 'id'
          final Map<String, int> fetchedBlocks = {
            for (var block in blocksList)
              (block['name'] as String): (block['id'] as int),
          };

          setState(() {
            _blocks = fetchedBlocks;
            _isLoadingBlocks = false;
          });
          print('DEBUG: Fetched blocks successfully: ${_blocks.length} items.');
          print('DEBUG: Blocks content: $_blocks');
        } else {
          throw Exception(
            'API returned success=false. Error: ${data['error']}',
          );
        }
      } else {
        throw Exception(
          'Failed to load blocks. Status Code: ${response.statusCode}',
        );
      }
    } catch (e, stacktrace) {
      setState(() {
        _isLoadingBlocks = false;
        _hasBlocksError = true;
      });
      _showSnackBar('Error fetching basins. Please try again.');
      print('==================== FETCH BLOCKS FAILED ====================');
      print('ERROR: $e');
      print('STACKTRACE: \n$stacktrace');
      print('===============================================================');
    }
  }
  // ⭐️⭐️⭐️ END OF MODIFICATION / نهاية التعديل ⭐️⭐️⭐️

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled. Please enable them.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_userLocation!, 15.0);
      _showSnackBar('Your current location loaded.');
    } catch (e) {
      _showSnackBar('Error getting current location: $e');
    }
  }

  Future<void> _searchParcelAndShowRoute() async {
    final parcel = _parcelController.text.trim();

    if (_hasLocalitiesError || _hasBlocksError) {
      _showAlertDialog(
        'Automatic Search Unavailable',
        'Cannot perform automatic search. Failed to load region or basin options. Please use manual selection.',
      );
      return;
    }
    if (_selectedLocalityId == null) {
      _showAlertDialog('Missing Data', 'Please select Region.');
      return;
    }
    if (_selectedBlockId == null) {
      _showAlertDialog('Missing Data', 'Please select Basin.');
      return;
    }
    if (parcel.isEmpty) {
      _showAlertDialog('Missing Data', 'Please enter Parcel Number.');
      return;
    }

    setState(() {
      _isSearchingParcel = true;
      _isManualSelectionMode = false;
      _parcelPolygonCoordinates = null;
      _parcelCenter = null;
      _routePoints = [];
    });

    try {
      final ParcelGeoResult? result = await _lwscGeoService
          .getParcelDetailsAndGeometry(parcel, _selectedBlockId!);

      if (result != null) {
        setState(() {
          _parcelPolygonCoordinates = result.coordinatesPolygon;
          _parcelCenter = result.centerCoordinate;
        });
        _mapController.move(_parcelCenter!, 16.0);

        _showSnackBar('Parcel found and displayed.');

        if (_userLocation != null && _parcelCenter != null) {
          _drawRoute(_userLocation!, _parcelCenter!);
        } else {
          _showSnackBar(
            'Cannot draw route: User location or parcel center not available.',
          );
        }
      } else {
        _showAlertDialog(
          'Parcel Not Found',
          'Could not find the parcel with the provided details.',
        );
      }
    } catch (e) {
      _showAlertDialog('Error', 'Failed to search parcel: $e');
    } finally {
      setState(() {
        _isSearchingParcel = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_isManualSelectionMode) return;

    setState(() {
      _parcelCenter = point;
      _parcelPolygonCoordinates = null;
      _routePoints = [];
    });
    _showSnackBar('Location set manually.');

    if (_userLocation != null && _parcelCenter != null) {
      _drawRoute(_userLocation!, _parcelCenter!);
    }
  }

  Future<void> _performGenericSearch() async {
    final query = _genericSearchController.text.trim();
    if (query.isEmpty) {
      _showSnackBar('Please enter a search query.');
      return;
    }

    _showSnackBar('Searching for "$query"...');
    try {
      final LatLng? result = await _nominatimService.getCoordinatesFromArea(
        query,
      );
      if (result != null) {
        _mapController.move(result, 15.0);
        _showSnackBar('Moved map to "$query".');
      } else {
        _showSnackBar('Location for "$query" not found.');
      }
    } catch (e) {
      _showSnackBar('Error during generic search: $e');
    }
  }

  // This function is now updated to allow choosing between the fastest and shortest route.
  Future<void> _drawRoute(LatLng start, LatLng end) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
    });

    const String openRouteServiceApiKey =
        '5b3ce3597851110001cf6248c8a94e6a10234e2aa666b69d1689a2ad'; // ⚠️⚠️⚠️ استبدلي هذا ⚠️⚠️⚠️
    if (openRouteServiceApiKey == 'YOUR_OPENROUTESERVICE_API_KEY') {
      _showSnackBar('Please get your OpenRouteService API Key for routing.');
      setState(() {
        _isLoadingRoute = false;
      });
      return;
    }

    // ⭐️⭐️⭐️ THE CHANGE IS HERE / التغيير هنا ⭐️⭐️⭐️
    // Choose your preference: 'fastest' (default) or 'shortest'
    // اختر ما تفضله: 'fastest' (الأسرع - الافتراضي) أو 'shortest' (الأقصر)
    const String preference = 'shortest';

    final Uri uri = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$openRouteServiceApiKey&preference=$preference&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}',
    );

    print('DEBUG: Requesting route with URL: $uri'); // For debugging

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept':
              'application/json, application/geo+json, application/gpx+xml, application/vnd.geo+json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final List<dynamic> coordinates =
              data['features'][0]['geometry']['coordinates'];
          List<LatLng> points =
              coordinates.map<LatLng>((coord) {
                return LatLng(coord[1], coord[0]);
              }).toList();

          setState(() {
            _routePoints = points;
          });
          _showSnackBar(
            'Route calculated successfully (Preference: $preference).',
          );
        } else {
          _showSnackBar('No route found for these locations.');
        }
      } else {
        _showSnackBar(
          'Failed to get route: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showSnackBar('Error calculating route: $e');
    } finally {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAlertDialog(String title, String message, {List<Widget>? actions}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions:
              actions ??
              [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🧠 تحديد عرض الكرت حسب عرض الشاشة (Responsive)
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth;

    if (screenWidth < 600) {
      // 📱 موبايل
      cardWidth = screenWidth * 0.95;
    } else if (screenWidth < 900) {
      // 📲 تابلت
      cardWidth = screenWidth * 0.5;
    } else {
      // 💻 ديسكتوب
      cardWidth = screenWidth * 0.25;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            /* IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
              color: Colors.white,
              onPressed: () => const HomeScreen(),
            ),*/
            Expanded(
              child: Text(
                "Parcel Viewer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(31.9522, 35.2332),
              initialZoom: 10,
              onTap: _onMapTap,
            ),
            children: [
              // 🗺 طبقات الخريطة
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.buildflow_frontend',
              ),
              TileLayer(
                urlTemplate:
                    'https://geomolg.ps/arcgis/rest/services/Parcels_RegisteredPalestinian/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.buildflow_frontend',
              ),

              // 🟦 عرض حدود القطعة إن وُجدت
              if (_parcelPolygonCoordinates != null &&
                  _parcelPolygonCoordinates!.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    for (var ringPoints in _parcelPolygonCoordinates!)
                      Polygon(
                        points: ringPoints,
                        isFilled: true,
                        borderColor: AppColors.accent,
                        borderStrokeWidth: 3,
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                  ],
                ),

              // 📍 مركز القطعة
              if (_parcelCenter != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _parcelCenter!,
                      width: 60,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),

              // 👤 موقع المستخدم
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 60,
                      height: 60,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 40,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),

              // 🧭 مسار الطريق
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: AppColors.info,
                      isDotted: true,
                    ),
                  ],
                ),
            ],
          ),

          // 🔎 البحث العام
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _genericSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search any location (e.g., Nablus)...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: AppColors.accent),
                      onPressed: _performGenericSearch,
                    ),
                  ),
                  onSubmitted: (_) => _performGenericSearch(),
                ),
              ),
            ),
          ),

          // 📦 كرت الإدخال: يتجاوب مع حجم الشاشة
          Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ⭐️⭐️⭐️ المنطقة: موحدة الشكل (DropdownButtonFormField حتى لو معطل) ⭐️⭐️⭐️
                      _isLoadingLocalities
                          ? const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : DropdownButtonFormField<String>(
                            // ⭐️⭐️⭐️ أصبح دائماً Dropdown ⭐️⭐️⭐️
                            decoration: InputDecoration(
                              labelText: 'Region',
                              errorText:
                                  _hasLocalitiesError
                                      ? 'Loading regions failed. Cannot search automatically.'
                                      : null,
                            ),
                            value: _selectedLocalityName,
                            hint:
                                _hasLocalitiesError
                                    ? const Text('Loading Failed')
                                    : const Text('Select Region'),
                            items:
                                _localities.keys.map((String name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                            onChanged:
                                _hasLocalitiesError
                                    ? null
                                    : (String? newValue) {
                                      setState(() {
                                        _selectedLocalityName = newValue;
                                        _selectedLocalityId =
                                            _localities[newValue];
                                        // Reset everything below when region changes
                                        _blocks = {};
                                        _selectedBasinName = null;
                                        _selectedBlockId = null;
                                        _parcelPolygonCoordinates = null;
                                        _parcelCenter = null;
                                        _routePoints = [];
                                      });
                                      if (_selectedLocalityId != null) {
                                        _fetchBlocks(_selectedLocalityId!);
                                      }
                                    },
                          ),
                      const SizedBox(height: 10),

                      // ⭐️⭐️⭐️ الحوض ⭐️⭐️⭐️
                      _isLoadingBlocks
                          ? const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Basin',
                              errorText:
                                  _hasBlocksError
                                      ? 'Loading basins failed. Cannot search automatically.'
                                      : null,
                            ),
                            value: _selectedBasinName,
                            hint:
                                _selectedLocalityId == null
                                    ? const Text('Select Region first')
                                    : _hasBlocksError
                                    ? const Text('Loading Failed')
                                    : const Text('Select Basin'),
                            items:
                                _blocks.keys.map((String name) {
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                            onChanged:
                                (_selectedLocalityId == null || _hasBlocksError)
                                    ? null
                                    : (String? newValue) {
                                      setState(() {
                                        _selectedBasinName = newValue;
                                        _selectedBlockId = _blocks[newValue];
                                        // Reset parcel details when basin changes
                                        _parcelPolygonCoordinates = null;
                                        _parcelCenter = null;
                                        _routePoints = [];
                                      });
                                    },
                          ),
                      const SizedBox(height: 10),

                      // 📩 رقم القطعة
                      TextField(
                        controller: _parcelController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Parcel Number',
                          labelText: 'Parcel Number',
                        ),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),

                      // 🔘 الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSearchingParcel ||
                                          _isManualSelectionMode ||
                                          _hasLocalitiesError ||
                                          _hasBlocksError
                                      ? null
                                      : _searchParcelAndShowRoute,
                              icon:
                                  _isSearchingParcel
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                      : const Icon(Icons.search),
                              label: Text(
                                _isSearchingParcel ? 'Searching...' : 'Search',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context)
                                      .elevatedButtonTheme
                                      .style
                                      ?.foregroundColor
                                      ?.resolve({}),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSearchingParcel
                                      ? null
                                      : () {
                                        setState(() {
                                          _isManualSelectionMode =
                                              !_isManualSelectionMode;
                                          if (_isManualSelectionMode) {
                                            _parcelPolygonCoordinates = null;
                                            _parcelCenter = null;
                                            _routePoints = [];
                                            _parcelController.clear();
                                            _selectedLocalityName = null;
                                            _selectedLocalityId = null;
                                            _selectedBasinName = null;
                                            _selectedBlockId = null;
                                            _showSnackBar(
                                              'Manual selection mode enabled. Tap on the map.',
                                            );
                                          } else {
                                            _showSnackBar(
                                              'Manual selection mode disabled.',
                                            );
                                          }
                                        });
                                      },
                              icon: Icon(
                                _isManualSelectionMode
                                    ? Icons.edit_off
                                    : Icons.touch_app,
                              ),
                              label: Text(
                                _isManualSelectionMode
                                    ? 'Manual ON'
                                    : 'Set Manually',
                                style: TextStyle(
                                  color:
                                      _isManualSelectionMode
                                          ? AppColors.textPrimary
                                          : AppColors.card,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isManualSelectionMode
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.accent,
                                foregroundColor:
                                    _isManualSelectionMode
                                        ? AppColors.accent
                                        : AppColors.card,
                                elevation: _isManualSelectionMode ? 0 : 4,
                                side:
                                    _isManualSelectionMode
                                        ? const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        )
                                        : BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isManualSelectionMode)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Manual mode: Tap on the map to set the parcel location.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // 📍 إحداثيات المستخدم
                      if (_userLocation != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            'Your Location: Lat: ${_userLocation!.latitude.toStringAsFixed(5)}, Lng: ${_userLocation!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
