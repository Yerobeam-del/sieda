import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/theme/app_theme.dart';
import '../services/location_service.dart';

/// A reusable widget that displays a mini OpenStreetMap, allows GPS location
/// detection, shows coordinates, and auto-fills the address field.
///
/// Provides callbacks for latitude, longitude, and address changes so the
/// parent form can include them in API submissions.
class LocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final ValueChanged<double>? onLatitudeChanged;
  final ValueChanged<double>? onLongitudeChanged;
  final ValueChanged<String>? onAddressChanged;
  final String? addressInitialValue;

  const LocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.onLatitudeChanged,
    this.onLongitudeChanged,
    this.onAddressChanged,
    this.addressInitialValue,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final _locationService = LocationService();
  double? _latitude;
  double? _longitude;
  bool _isDetecting = false;
  String? _errorMessage;
  final _addressController = TextEditingController();
  bool _isOnline = true;

  bool get _hasLocation => _latitude != null && _longitude != null;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _addressController.text = widget.addressInitialValue ?? '';
    _addressController.addListener(_onAddressChanged);
    _checkConnectivity();
  }

  void _onAddressChanged() {
    widget.onAddressChanged?.call(_addressController.text);
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (mounted) {
        setState(() => _isOnline = !result.contains(ConnectivityResult.none));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    final position = await _locationService.getCurrentPosition();
    if (!mounted) return;

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isDetecting = false;
      });

      // Auto-fill alamat dengan koordinat
      final autoAddress = LocationService.addressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      _addressController.text = autoAddress;

      widget.onLatitudeChanged?.call(position.latitude);
      widget.onLongitudeChanged?.call(position.longitude);
      widget.onAddressChanged?.call(autoAddress);
    } else {
      setState(() {
        _isDetecting = false;
        _errorMessage = 'Tidak dapat mendeteksi lokasi. Periksa GPS dan izin lokasi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecorationOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lokasi Survey',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                ),
                if (_isDetecting)
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  GestureDetector(
                    onTap: _detectLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _hasLocation ? Icons.my_location_rounded : Icons.gps_fixed_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _hasLocation ? 'Deteksi Ulang' : 'Deteksi',
                            style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mini Map View — with offline fallback
          Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderOf(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: _hasLocation
                ? _isOnline
                    ? FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(_latitude!, _longitude!),
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.sieda.app',
                            maxZoom: 19,
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(_latitude!, _longitude!),
                                width: 40,
                                height: 40,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 36, color: AppTheme.error),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    // Offline fallback: stylized coordinate card
                    : Container(
                        color: AppTheme.surfaceOf(context),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_rounded, size: 40, color: AppTheme.primary.withValues(alpha: 0.3)),
                              const SizedBox(height: 8),
                              Text('Peta tidak tersedia (offline)', style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                              const SizedBox(height: 4),
                              Text(
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ),
                      )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 40, color: AppTheme.textHintOf(context).withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan "Deteksi" untuk menampilkan peta',
                          style: TextStyle(fontSize: 12, color: AppTheme.textHintOf(context)),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Coordinates Display
          if (_hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Latitude', style: TextStyle(fontSize: 9, color: AppTheme.textHintOf(context))),
                          const SizedBox(height: 2),
                          Text(
                            _latitude!.toStringAsFixed(6),
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.info.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Longitude', style: TextStyle(fontSize: 9, color: AppTheme.textHintOf(context))),
                          const SizedBox(height: 2),
                          Text(
                            _longitude!.toStringAsFixed(6),
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isOnline)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.cloud_off_rounded, size: 14, color: AppTheme.textHintOf(context)),
                    ),
                ],
              ),
            ),

          // Error Message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11, color: AppTheme.error),
              ),
            ),

          // Address Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Alamat / Lokasi',
                hintText: _hasLocation
                    ? 'Alamat sekitar koordinat di atas'
                    : 'Masukkan alamat atau deteksi lokasi',
                prefixIcon: const Icon(Icons.home_outlined, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.borderOf(context)),
                ),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ),
    );
  }
}
