import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerModal extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerModal({super.key, this.initialLocation});

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    _determineInitialPosition();
  }

  Future<void> _determineInitialPosition() async {
    if (_pickedLocation != null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    setState(() {
      _pickedLocation = const LatLng(37.7749, -122.4194); // SF Default
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Tactical Notch
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GEOSPATIAL TARGETING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select Mission Site',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pickedLocation!,
                          initialZoom: 15,
                          onTap: (tapPosition, point) {
                            setState(() => _pickedLocation = point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.inspectsync.app',
                            tileBuilder: (context, tileWidget, tile) {
                              return ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1.0,
                                  0.0,
                                  0.0,
                                  0.0,
                                  255.0,
                                  0.0,
                                  -1.0,
                                  0.0,
                                  0.0,
                                  255.0,
                                  0.0,
                                  0.0,
                                  -1.0,
                                  0.0,
                                  255.0,
                                  0.0,
                                  0.0,
                                  0.0,
                                  1.0,
                                  0.0,
                                ]),
                                child: tileWidget,
                              );
                            },
                          ),
                          if (_pickedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _pickedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: colorScheme.primary,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Crosshair overlay
                      IgnorePointer(
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        ),
                      ),

                      // My Location Button
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: colorScheme.surface,
                          foregroundColor: colorScheme.primary,
                          onPressed: () async {
                            final pos = await Geolocator.getCurrentPosition();
                            final point = LatLng(pos.latitude, pos.longitude);
                            _mapController.move(point, 15);
                            setState(() => _pickedLocation = point);
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
          ),

          // Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pickedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'COORD: ${_pickedLocation!.latitude.toStringAsFixed(6)}, ${_pickedLocation!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _pickedLocation == null
                        ? null
                        : () {
                            Navigator.pop(context, _pickedLocation);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM SITE SELECTION',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
