import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../ui/mobile/mobile_components.dart';
import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../ui/web/web_tokens.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/geo_utils.dart';
import '../../utils/location_lookup.dart';
import '../../utils/user_roles.dart';
import '../../widgets/service_map_preview.dart';
import 'service_detail_screen.dart';
import 'service_map_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key, this.showOnlyMine = false});

  final bool showOnlyMine;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  static const double _defaultRadiusKm = 10;
  static const double _maxRadiusKm = 100;
  static const double _radiusStepKm = 10;

  final _categoryController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _category = '';
  String _district = '';
  String _city = '';
  bool _nearMe = false;
  bool _onlyWithCoordinates = false;
  bool _requestingLocation = false;
  String? _nearMeError;
  double _radiusKm = _defaultRadiusKm;
  double? _minPrice;
  double? _maxPrice;
  LatLng? _currentPosition;
  bool _autoNearMeRequested = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _category = _categoryController.text.trim();
      _district = _districtController.text.trim();
      _city = _cityController.text.trim();
      _minPrice = double.tryParse(_minPriceController.text.trim());
      _maxPrice = double.tryParse(_maxPriceController.text.trim());
    });
  }

  Query<Map<String, dynamic>> _buildQuery(String role, String userId) {
    Query<Map<String, dynamic>> query = FirestoreRefs.services();

    if (widget.showOnlyMine) {
      query = query.where('providerId', isEqualTo: userId);
    } else if (role == UserRoles.seeker) {
      query = query.where('status', isEqualTo: 'approved');
    }

    return query;
  }

  Future<void> _handleNearMeToggle(bool value) async {
    if (!value) {
      setState(() {
        _nearMe = false;
        _nearMeError = null;
      });
      return;
    }

    setState(() {
      _requestingLocation = true;
      _nearMeError = null;
    });

    final result = await _resolveCurrentPosition();

    if (!mounted) return;
    setState(() {
      _requestingLocation = false;
      _nearMe = result != null;
      _currentPosition = result;
      if (result == null) {
        _nearMeError = 'Location unavailable. Falling back to city/district.';
      }
    });
  }

  Future<LatLng?> _resolveCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void _autoEnableNearMeIfNeeded(String role) {
    if (_autoNearMeRequested ||
        widget.showOnlyMine ||
        role != UserRoles.seeker) {
      return;
    }
    _autoNearMeRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleNearMeToggle(true);
    });
  }

  void _expandRadius() {
    if (_radiusKm >= _maxRadiusKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Max radius reached. Try city/district filters.'),
        ),
      );
      return;
    }
    setState(() {
      _radiusKm = (_radiusKm + _radiusStepKm).clamp(0, _maxRadiusKm);
    });
  }

  List<_ServiceViewItem> _applyClientFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String userDistrict,
    required String userCity,
  }) {
    final useGps = _nearMe && _currentPosition != null;
    final effectiveDistrict = useGps
        ? ''
        : (_nearMe ? userDistrict : _district);
    final effectiveCity = useGps ? '' : (_nearMe ? userCity : _city);

    final normalizedCategory = _category.toLowerCase();
    final normalizedDistrict = effectiveDistrict.toLowerCase();
    final normalizedCity = effectiveCity.toLowerCase();

    final filtered = <_ServiceViewItem>[];
    for (final doc in docs) {
      final data = doc.data();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final district = (data['district'] ?? '').toString().toLowerCase();
      final city = (data['city'] ?? '').toString().toLowerCase();
      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : 0.0;
      final point = GeoUtils.extractPoint(data);

      if (normalizedCategory.isNotEmpty && category != normalizedCategory) {
        continue;
      }
      if (normalizedDistrict.isNotEmpty && district != normalizedDistrict) {
        continue;
      }
      if (normalizedCity.isNotEmpty && city != normalizedCity) {
        continue;
      }
      if (_minPrice != null && price < _minPrice!) continue;
      if (_maxPrice != null && price > _maxPrice!) continue;
      if (_onlyWithCoordinates && point == null) continue;

      double? distanceKm;
      if (useGps && point != null) {
        distanceKm = GeoUtils.distanceKm(
          fromLat: _currentPosition!.latitude,
          fromLng: _currentPosition!.longitude,
          toLat: point.latitude,
          toLng: point.longitude,
        );
        if (distanceKm > _radiusKm) {
          continue;
        }
      }

      filtered.add(
        _ServiceViewItem(doc: doc, point: point, distanceKm: distanceKm),
      );
    }

    filtered.sort((a, b) {
      if (useGps) {
        if (a.distanceKm != null && b.distanceKm != null) {
          return a.distanceKm!.compareTo(b.distanceKm!);
        }
        if (a.distanceKm != null) return -1;
        if (b.distanceKm != null) return 1;
      }
      final aTs = a.doc.data()['createdAt'];
      final bTs = b.doc.data()['createdAt'];
      final aMillis = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
      final bMillis = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
      return bMillis.compareTo(aMillis);
    });

    return filtered;
  }

  String _displayLocation(Map<String, dynamic> data) {
    final city = (data['city'] ?? '').toString().trim();
    final district = (data['district'] ?? '').toString().trim();
    if (city.isNotEmpty || district.isNotEmpty) {
      return '$city, $district';
    }
    return (data['location'] ?? '').toString();
  }

  Future<void> _openMapView(List<_ServiceViewItem> items) async {
    final mapItems = items
        .map((item) {
          final exactPoint = item.point;
          if (exactPoint != null) {
            return ServiceMapItem(
              serviceId: item.doc.id,
              title: (item.doc.data()['title'] ?? 'Service').toString(),
              locationLabel: _displayLocation(item.doc.data()),
              priceLabel: 'LKR ${item.doc.data()['price'] ?? ''}',
              point: exactPoint,
              isApproximate: false,
              pointSource: 'Exact',
            );
          }

          final resolved = LocationLookup.resolve(
            city: item.doc.data()['city'],
            district: item.doc.data()['district'],
          );
          if (resolved == null) return null;

          return ServiceMapItem(
            serviceId: item.doc.id,
            title: (item.doc.data()['title'] ?? 'Service').toString(),
            locationLabel: _displayLocation(item.doc.data()),
            priceLabel: 'LKR ${item.doc.data()['price'] ?? ''}',
            point: resolved.point,
            isApproximate: resolved.isApproximate,
            pointSource: resolved.sourceLabel,
          );
        })
        .whereType<ServiceMapItem>()
        .toList();

    if (mapItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No mappable locations found. Add city/district or coordinates to view services on map.',
          ),
        ),
      );
      return;
    }

    final selectedServiceId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ServiceMapScreen(items: mapItems, initialCenter: _currentPosition),
      ),
    );

    if (!mounted || selectedServiceId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(serviceId: selectedServiceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.users().doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() ?? {};
        final role = UserRoles.normalize(userData['role']);
        final userDistrict = (userData['district'] ?? '').toString().trim();
        final userCity = (userData['city'] ?? '').toString().trim();
        _autoEnableNearMeIfNeeded(role);

        final content = Column(
          children: [
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.all(WebTokens.spacingMd),
                child: Card(
                  elevation: 0,
                  color: WebTokens.surfaceMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WebTokens.radiusMd),
                    side: const BorderSide(color: WebTokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(WebTokens.spacingMd),
                    child: _filters(),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: MobileSectionCard(child: _filters()),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _buildQuery(role, user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Failed to load services: ${snapshot.error}'),
                    );
                  }

                  final items = _applyClientFilters(
                    snapshot.data?.docs ?? [],
                    userDistrict: userDistrict,
                    userCity: userCity,
                  );

                  if (items.isEmpty) {
                    if (_nearMe) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('No nearby services found.'),
                              const SizedBox(height: 8),
                              Text('Current radius: ${_radiusKm.toInt()} km'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _expandRadius,
                                child: const Text('Expand radius (+10 km)'),
                              ),
                              if (_radiusKm >= _maxRadiusKm) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Maximum radius reached. Try district/city filters.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    if (kIsWeb) {
                      return const Center(child: Text('No services found.'));
                    }
                    return const MobileEmptyState(
                      title: 'No services found.',
                      icon: Icons.search_off,
                    );
                  }

                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextButton.icon(
                            onPressed: () => _openMapView(items),
                            icon: const Icon(Icons.map),
                            label: const Text('Map view'),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final data = item.doc.data();
                            final point = item.point;
                            final distance = item.distanceKm;
                            final status =
                                (data['status'] ?? 'pending').toString();
                            final onSurface = Theme.of(
                              context,
                            ).colorScheme.onSurface;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Card(
                                child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                        data['title'] ?? 'Service',
                                        style: TextStyle(color: onSurface),
                                      ),
                                      subtitle: Text(
                                        '${data['category'] ?? ''} | ${_displayLocation(data)} | LKR ${data['price'] ?? ''}',
                                        style: TextStyle(
                                          color: onSurface.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          MobileStatusChip(
                                            label: status,
                                            color: status == 'approved'
                                                ? MobileTokens.secondary
                                                : status == 'rejected'
                                                ? Colors.red
                                                : MobileTokens.accent,
                                          ),
                                          if (_nearMe)
                                            Text(
                                              distance != null
                                                  ? GeoUtils.formatKm(distance)
                                                  : 'Distance N/A',
                                              style: TextStyle(
                                                color: onSurface.withValues(
                                                  alpha: 0.75,
                                                ),
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ServiceDetailScreen(
                                            serviceId: item.doc.id,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (point != null)
                                      ServiceMapPreview(
                                        point: point,
                                        title: (data['title'] ?? 'Service')
                                            .toString(),
                                        height: 130,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ServiceMapScreen(
                                              items: [
                                                ServiceMapItem(
                                                  serviceId: item.doc.id,
                                                  title:
                                                      (data['title'] ??
                                                              'Service')
                                                          .toString(),
                                                  locationLabel:
                                                      _displayLocation(data),
                                                  priceLabel:
                                                      'LKR ${data['price'] ?? ''}',
                                                  point: point,
                                                  isApproximate: false,
                                                  pointSource: 'Exact',
                                                ),
                                              ],
                                              initialCenter: point,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );

        if (!kIsWeb) {
          final roleVisuals = RoleVisuals.forRole(role);
          return MobilePageScaffold(
            title: widget.showOnlyMine ? 'My Services' : 'Services',
            subtitle: widget.showOnlyMine
                ? 'Manage and track your service listings'
                : 'Discover trusted local services near you',
            accentColor: roleVisuals.accent,
            body: content,
          );
        }

        return WebPageScaffold(
          title: widget.showOnlyMine ? 'My Services' : 'Service Marketplace',
          subtitle: widget.showOnlyMine
              ? 'Manage and review your posted services.'
              : 'Find and filter services across districts and cities.',
          useScaffold: false,
          child: content,
        );
      },
    );
  }

  Widget _filters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'District',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Near me'),
                value: _nearMe,
                onChanged: _requestingLocation ? null : _handleNearMeToggle,
              ),
            ),
          ],
        ),
        if (_requestingLocation)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Requesting current location...',
              style: TextStyle(fontSize: 12),
            ),
          ),
        if (_nearMeError != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _nearMeError!,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (_nearMe)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<double>(
                  initialValue: _radiusKm,
                  decoration: const InputDecoration(
                    labelText: 'Radius',
                  ),
                  items: const [2.0, 5.0, 10.0, 25.0]
                      .map(
                        (value) => DropdownMenuItem<double>(
                          value: value,
                          child: Text('${value.toInt()} km'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _onlyWithCoordinates,
                  title: const Text('Coordinates only'),
                  onChanged: (value) {
                    setState(() {
                      _onlyWithCoordinates = value ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min price',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max price',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Filter'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceViewItem {
  const _ServiceViewItem({
    required this.doc,
    required this.point,
    required this.distanceKm,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final LatLng? point;
  final double? distanceKm;
}
