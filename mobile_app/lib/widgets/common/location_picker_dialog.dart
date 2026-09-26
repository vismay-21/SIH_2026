import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import 'shared_widgets.dart';

class PickedLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String googleMapsLink;

  const PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.googleMapsLink,
  });

  static String generateGoogleMapsLink(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
  }
}

class LocationPickerDialog extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerDialog({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  static Future<PickedLocation?> show(
    BuildContext context, {
    String? initialAddress,
    double? initialLat,
    double? initialLng,
  }) {
    return showModalBottomSheet<PickedLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerDialog(
        initialAddress: initialAddress,
        initialLat: initialLat,
        initialLng: initialLng,
      ),
    );
  }

  /// Real device GPS with fallback to IP-based network location and Nominatim reverse geocoding
  static Future<PickedLocation?> getCurrentLocation() async {
    double? lat;
    double? lng;

    // 1. Try real GPS via Geolocator
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          try {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          } catch (_) {
            final last = await Geolocator.getLastKnownPosition();
            if (last != null) {
              lat = last.latitude;
              lng = last.longitude;
            }
          }
        }
      }
    } catch (_) {}

    // 2. Fallback to IP-based location if GPS is unavailable / denied
    if (lat == null || lng == null) {
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        final res = await dio.get<Map<String, dynamic>>('https://ipapi.co/json/');
        if (res.statusCode == 200 && res.data != null) {
          lat = (res.data!['latitude'] as num?)?.toDouble();
          lng = (res.data!['longitude'] as num?)?.toDouble();
        }
      } catch (_) {
        try {
          final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 3)));
          final res = await dio.get<Map<String, dynamic>>('http://ip-api.com/json/');
          if (res.statusCode == 200 && res.data != null) {
            lat = (res.data!['lat'] as num?)?.toDouble();
            lng = (res.data!['lon'] as num?)?.toDouble();
          }
        } catch (_) {}
      }
    }

    if (lat == null || lng == null) {
      return null;
    }

    // 3. Reverse-geocode coordinates to readable address
    String formattedAddress = '';
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: {'User-Agent': 'SahakaarSevaApp/1.0 (info@sahakaar.coop)'},
        ),
      );
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat.toStringAsFixed(6)}&lon=${lng.toStringAsFixed(6)}&zoom=18&addressdetails=1';
      final response = await dio.get<Map<String, dynamic>>(url);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'];
          final city = addr['city'] ?? addr['town'] ?? addr['state_district'] ?? addr['state'];
          final postcode = addr['postcode'];
          final parts = <String>[];
          if (road != null && road.toString().isNotEmpty) parts.add(road.toString());
          if (city != null && city.toString().isNotEmpty) parts.add(city.toString());
          if (postcode != null && postcode.toString().isNotEmpty) parts.add(postcode.toString());
          if (parts.isNotEmpty) {
            formattedAddress = parts.join(', ');
          }
        }
        if (formattedAddress.isEmpty) {
          formattedAddress = (data['display_name'] as String?)?.split(',').take(3).join(',').trim() ?? '';
        }
      }
    } catch (_) {}

    if (formattedAddress.isEmpty) {
      formattedAddress = 'Current Location (${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°)';
    }

    return PickedLocation(
      address: formattedAddress,
      latitude: lat,
      longitude: lng,
      googleMapsLink: PickedLocation.generateGoogleMapsLink(lat, lng),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late final TextEditingController _addressController;
  late final MapController _mapController;
  late LatLng _center;
  double _currentZoom = 15.5;
  bool _isGeocoding = false;
  bool _isSearching = false;
  bool _isLocating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat ?? 20.5937;
    final lng = widget.initialLng ?? 78.9629;
    _center = LatLng(lat, lng);
    _currentZoom = widget.initialLat != null ? 15.5 : 5.0;
    _mapController = MapController();

    String initName = widget.initialAddress ?? '';
    if (initName.isEmpty) {
      initName = widget.initialLat != null ? 'Selected Location' : '';
    }
    _addressController = TextEditingController(text: initName);

    // Auto-detect current location if not previously pinned
    if (widget.initialLat == null || widget.initialLng == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detectCurrentLocation(showFeedback: false);
      });
    }
  }

  Future<void> _detectCurrentLocation({bool showFeedback = true}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final loc = await LocationPickerDialog.getCurrentLocation();
      if (!mounted) return;

      if (loc != null) {
        final target = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _center = target;
          _addressController.text = loc.address;
          _isLocating = false;
        });
        _mapController.move(target, 16.5);

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Centered to current location: ${loc.address}'),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() => _isLocating = false);
        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not access current location. Please ensure device location / GPS is turned on, or drag the map pin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapMoved() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 650), () {
      _reverseGeocode(_center.latitude, _center.longitude);
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
          headers: {'User-Agent': 'SahakaarSevaApp/1.0 (info@sahakaar.coop)'},
        ),
      );

      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat.toStringAsFixed(6)}&lon=${lng.toStringAsFixed(6)}&zoom=18&addressdetails=1';
      final response = await dio.get<Map<String, dynamic>>(url);

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final addr = data['address'] as Map<String, dynamic>?;

        String formatted = '';
        if (addr != null) {
          final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'];
          final city = addr['city'] ?? addr['town'] ?? addr['state_district'] ?? addr['state'];
          final postcode = addr['postcode'];

          final parts = <String>[];
          if (road != null && road.toString().isNotEmpty) parts.add(road.toString());
          if (city != null && city.toString().isNotEmpty) parts.add(city.toString());
          if (postcode != null && postcode.toString().isNotEmpty) parts.add(postcode.toString());

          if (parts.isNotEmpty) {
            formatted = parts.join(', ');
          }
        }

        if (formatted.isEmpty) {
          formatted = (data['display_name'] as String?)?.split(',').take(3).join(',').trim() ?? '';
        }

        if (formatted.isNotEmpty) {
          setState(() {
            _addressController.text = formatted;
            _isGeocoding = false;
          });
          return;
        }
      }
    } catch (_) {
      // Graceful fallback to nearest preset or current coordinates label
    }

    if (mounted) {
      setState(() => _isGeocoding = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'User-Agent': 'SahakaarSevaApp/1.0 (info@sahakaar.coop)'},
        ),
      );

      final url =
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(trimmed)}&limit=1';
      final response = await dio.get<List<dynamic>>(url);

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null && response.data!.isNotEmpty) {
        final first = response.data!.first as Map<String, dynamic>;
        final lat = double.tryParse(first['lat'].toString());
        final lon = double.tryParse(first['lon'].toString());

        if (lat != null && lon != null) {
          final target = LatLng(lat, lon);
          setState(() {
            _center = target;
            _isSearching = false;
          });
          _mapController.move(target, 16.0);
          _reverseGeocode(lat, lon);
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find location. Try dragging or zooming the map to pin your location.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmSelection() {
    final address = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : 'Pinpointed Location';
    final link = PickedLocation.generateGoogleMapsLink(_center.latitude, _center.longitude);

    Navigator.of(context).pop(
      PickedLocation(
        address: address,
        latitude: _center.latitude,
        longitude: _center.longitude,
        googleMapsLink: link,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapLink = PickedLocation.generateGoogleMapsLink(_center.latitude, _center.longitude);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Exact Service Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Move map to position pin at customer doorstep',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              controller: _addressController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchLocation,
              decoration: InputDecoration(
                hintText: 'Search landmark, area or apartment...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _isSearching || _isGeocoding
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                        tooltip: 'Search place',
                        onPressed: () => _searchLocation(_addressController.text),
                      ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Real Interactive Map Container
          Expanded(
            child: Stack(
              children: [
                // 1. FlutterMap with Real CartoDB / OSM Street Tiles
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _currentZoom,
                    minZoom: 4.0,
                    maxZoom: 19.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      if (hasGesture) {
                        _center = camera.center;
                        _currentZoom = camera.zoom;
                        _onMapMoved();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sahakaarseva.mobile_app',
                      maxZoom: 19,
                    ),
                  ],
                ),

                // 2. Central Pin Drop Marker (Stationary over moving map, Zomato style)
                IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Service Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 46,
                          color: AppColors.primary,
                        ),
                        Container(
                          width: 12,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 38), // Offset so pin point touches map center
                      ],
                    ),
                  ),
                ),

                // 3. Map Controls: Zoom In / Out & Reset
                Positioned(
                  right: 14,
                  bottom: 24,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.text,
                        elevation: 3,
                        onPressed: () {
                          _currentZoom = (_currentZoom + 1).clamp(4.0, 19.0);
                          _mapController.move(_center, _currentZoom);
                        },
                        child: const Icon(Icons.add_rounded),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.text,
                        elevation: 3,
                        onPressed: () {
                          _currentZoom = (_currentZoom - 1).clamp(4.0, 19.0);
                          _mapController.move(_center, _currentZoom);
                        },
                        child: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton.small(
                        heroTag: 'map_recenter',
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        tooltip: 'Current location',
                        onPressed: _isLocating ? null : () => _detectCurrentLocation(showFeedback: true),
                        child: _isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Confirmation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.place_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _addressController.text.isNotEmpty
                                  ? _addressController.text
                                  : 'Selected Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GPS: ${_center.latitude.toStringAsFixed(4)}° N, ${_center.longitude.toStringAsFixed(4)}° E',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => launchGoogleMaps(context, mapLink),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text(
                          'Google Maps',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryAction(
                      label: 'Confirm Location & Proceed',
                      icon: Icons.check_circle_rounded,
                      onPressed: _confirmSelection,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Utility function to launch Google Maps URL in web or native app
Future<void> launchGoogleMaps(BuildContext context, String url) async {
  String cleanUrl = url.trim();
  if (!cleanUrl.startsWith('http://') &&
      !cleanUrl.startsWith('https://') &&
      !cleanUrl.startsWith('geo:')) {
    cleanUrl =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(cleanUrl)}';
  }

  try {
    final uri = Uri.parse(cleanUrl);
    bool launched = false;

    // Try launching as external application (opens native Google Maps app on Android/iOS, or new browser tab on Web)
    try {
      launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    // If external app launch failed, try platform default
    if (!launched) {
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      } catch (_) {
        launched = false;
      }
    }

    if (!launched) {
      // Fallback: Copy link to clipboard
      await Clipboard.setData(ClipboardData(text: cleanUrl));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open map directly. Navigation link copied to clipboard!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    await Clipboard.setData(ClipboardData(text: cleanUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigation link copied to clipboard: $cleanUrl'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
