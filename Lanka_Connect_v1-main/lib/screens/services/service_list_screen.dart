import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/user_roles.dart';
import 'service_detail_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key, this.showOnlyMine = false});

  final bool showOnlyMine;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _categoryController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _category = '';
  String _district = '';
  String _city = '';
  bool _nearMe = false;
  double? _minPrice;
  double? _maxPrice;

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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyClientFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String userDistrict,
    required String userCity,
  }) {
    final effectiveDistrict = _nearMe ? userDistrict : _district;
    final effectiveCity = _nearMe ? userCity : _city;

    final normalizedCategory = _category.toLowerCase();
    final normalizedDistrict = effectiveDistrict.toLowerCase();
    final normalizedCity = effectiveCity.toLowerCase();

    var filtered = docs.where((doc) {
      final data = doc.data();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final district = (data['district'] ?? '').toString().toLowerCase();
      final city = (data['city'] ?? '').toString().toLowerCase();
      final price = (data['price'] is num)
          ? (data['price'] as num).toDouble()
          : 0.0;

      if (normalizedCategory.isNotEmpty && category != normalizedCategory) {
        return false;
      }

      if (normalizedDistrict.isNotEmpty && district != normalizedDistrict) {
        return false;
      }

      if (normalizedCity.isNotEmpty && city != normalizedCity) {
        return false;
      }

      if (_minPrice != null && price < _minPrice!) {
        return false;
      }

      if (_maxPrice != null && price > _maxPrice!) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aTs = a.data()['createdAt'];
      final bTs = b.data()['createdAt'];
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
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
                          onChanged: (value) {
                            setState(() {
                              _nearMe = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_nearMe && (userDistrict.isEmpty || userCity.isEmpty))
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Set your district and city in Profile to use Near me.',
                        style: TextStyle(fontSize: 12),
                      ),
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
              ),
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

                  final docs = _applyClientFilters(
                    snapshot.data?.docs ?? [],
                    userDistrict: userDistrict,
                    userCity: userCity,
                  );

                  if (docs.isEmpty) {
                    return const Center(child: Text('No services found.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(data['title'] ?? 'Service'),
                          subtitle: Text(
                            '${data['category'] ?? ''} | ${_displayLocation(data)} | LKR ${data['price'] ?? ''}',
                          ),
                          trailing: Text(
                            (data['status'] ?? 'pending').toString(),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailScreen(serviceId: doc.id),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
