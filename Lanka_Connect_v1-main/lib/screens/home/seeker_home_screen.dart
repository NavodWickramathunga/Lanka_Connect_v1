import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../ui/theme/design_tokens.dart';
import '../../utils/display_name_utils.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/category_bar.dart';
import '../../widgets/promotion_section.dart';
import '../../widgets/service_card_enhanced.dart';
import '../services/service_detail_screen.dart';
import '../services/service_list_screen.dart';

/// The enhanced seeker home screen matching the React SeekerHome component.
/// Combines BannerCarousel + CategoryBar + PromotionSection + Service grid
/// with the existing Firebase/Firestore backend.
class SeekerHomeScreen extends StatefulWidget {
  const SeekerHomeScreen({super.key});

  @override
  State<SeekerHomeScreen> createState() => _SeekerHomeScreenState();
}

class _SeekerHomeScreenState extends State<SeekerHomeScreen> {
  String _selectedCategory = '';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  LatLng? _currentPosition;
  bool _locationResolved = false;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _locationResolved = true;
        });
      }
    } catch (_) {
      // Silently ignore – location is optional for the home screen
    }
  }

  Query<Map<String, dynamic>> _buildServiceQuery() {
    Query<Map<String, dynamic>> query = FirestoreRefs.services()
        .where('status', isEqualTo: 'approved')
        .limit(20);
    return query;
  }

  String _displayLocation(Map<String, dynamic> data) {
    return DisplayNameUtils.locationLabel(
      city: data['city'],
      district: data['district'],
      fallback: (data['location'] ?? '').toString(),
    );
  }

  String? _computeDistance(Map<String, dynamic> data) {
    if (_currentPosition == null) return null;
    final point = GeoUtils.extractPoint(data);
    if (point == null) return null;
    final km = GeoUtils.distanceKm(
      fromLat: _currentPosition!.latitude,
      fromLng: _currentPosition!.longitude,
      toLat: point.latitude,
      toLng: point.longitude,
    );
    return GeoUtils.formatKm(km);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      color: DesignTokens.brandPrimary,
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Greeting header
          SliverToBoxAdapter(
            child: _buildGreetingHeader(context, user, isDark),
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: DesignTokens.textSubtle,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[850]
                      : DesignTokens.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Banner carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BannerCarousel(
                onCtaTap: (index) {
                  // 0 = Spring Cleaning, 1 = Emergency Plumbing, 2 = Join as Pro
                  if (index == 0 || index == 1) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServiceListScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Provider registration – coming soon!'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Category bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CategoryBar(
                selected: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),
          ),

          // Promotions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PromotionSection(
                onViewAll: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ServiceListScreen(),
                    ),
                  );
                },
                onPromoTap: (index) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ServiceListScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Services section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory.isEmpty
                        ? 'Popular Services'
                        : '$_selectedCategory Services',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_locationResolved)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: DesignTokens.brandPrimary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Nearby',
                          style: TextStyle(
                            fontSize: 12,
                            color: DesignTokens.brandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Services grid (Firestore-backed)
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _buildServiceQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Client-side filtering for category & search
              if (_selectedCategory.isNotEmpty) {
                docs = docs
                    .where(
                      (doc) =>
                          (doc.data()['category'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          _selectedCategory.toLowerCase(),
                    )
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                docs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '')
                      .toString()
                      .toLowerCase();
                  final cat = (data['category'] ?? '').toString().toLowerCase();
                  return title.contains(query) ||
                      desc.contains(query) ||
                      cat.contains(query);
                }).toList();
              }

              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: DesignTokens.textSubtle.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No services found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: DesignTokens.textSubtle),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCategory.isNotEmpty
                              ? 'Try a different category or clear selection'
                              : 'Try adjusting your search',
                          style: TextStyle(
                            color: DesignTokens.textSubtle,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.58,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = docs[index].data();
                    final rawImages = data['imageUrls'];
                    final imageUrl = (rawImages is List && rawImages.isNotEmpty)
                        ? rawImages.first.toString()
                        : null;
                    final price = (data['price'] is num)
                        ? (data['price'] as num).toDouble()
                        : 0.0;
                    final rating = (data['rating'] is num)
                        ? (data['rating'] as num).toDouble()
                        : 0.0;
                    final reviewCount = (data['reviewCount'] is num)
                        ? (data['reviewCount'] as num).toInt()
                        : 0;

                    return ServiceCardEnhanced(
                      title: (data['title'] ?? 'Untitled Service').toString(),
                      category: (data['category'] ?? 'Other').toString(),
                      price: price,
                      imageUrl: imageUrl,
                      rating: rating,
                      reviewCount: reviewCount,
                      location: _displayLocation(data),
                      distance: _computeDistance(data),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ServiceDetailScreen(serviceId: docs[index].id),
                        ),
                      ),
                    );
                  }, childCount: docs.length),
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, User? user, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_cloudy;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!.split(' ').first
        : 'there';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  DesignTokens.brandPrimary.withValues(alpha: 0.3),
                  Colors.transparent,
                ]
              : [
                  DesignTokens.brandPrimary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      size: 20,
                      color: DesignTokens.brandSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$greeting, $displayName!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Find the perfect service for your needs',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : DesignTokens.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: DesignTokens.brandPrimary.withValues(alpha: 0.15),
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(
                color: DesignTokens.brandPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
