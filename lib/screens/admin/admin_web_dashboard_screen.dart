import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../ui/web/web_page_scaffold.dart';
import '../../utils/display_name_utils.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/user_roles.dart';
import 'admin_services_screen.dart';

class AdminWebDashboardScreen extends StatelessWidget {
  const AdminWebDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = DefaultTabController(
      length: 3,
      child: Column(
        children: const [
          TabBar(
            tabs: [
              Tab(text: 'Moderation'),
              Tab(text: 'Users'),
              Tab(text: 'Analytics'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                AdminServicesScreen(),
                _UsersPanel(),
                _AnalyticsPanel(),
              ],
            ),
          ),
        ],
      ),
    );

    if (!kIsWeb) return content;

    return WebPageScaffold(
      title: 'Admin Dashboard',
      subtitle: 'Monitor moderation, users, and platform analytics.',
      useScaffold: false,
      child: content,
    );
  }
}

class _UsersPanel extends StatefulWidget {
  const _UsersPanel();

  @override
  State<_UsersPanel> createState() => _UsersPanelState();
}

class _UsersPanelState extends State<_UsersPanel> {
  String _userSearch = '';
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _userSearch = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _roleFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'provider', child: Text('Providers')),
                  DropdownMenuItem(value: 'seeker', child: Text('Seekers')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _roleFilter = v);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── User list ──
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestoreRefs.users().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Failed to load users: ${snapshot.error}'),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Role filter
              if (_roleFilter != 'all') {
                docs = docs.where((d) {
                  final role = UserRoles.normalize(
                    d.data()['role'],
                  ).toLowerCase();
                  return role == _roleFilter;
                }).toList();
              }

              // Search filter
              if (_userSearch.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_userSearch) ||
                      email.contains(_userSearch);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(child: Text('No users match the filters.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                separatorBuilder: (_, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final role = UserRoles.normalize(data['role']);
                  final roleLabel =
                      role.substring(0, 1).toUpperCase() + role.substring(1);
                  final displayName = DisplayNameUtils.userDisplayName(
                    uid: doc.id,
                    name: data['name'],
                    email: data['email'],
                  );
                  final location = DisplayNameUtils.locationLabel(
                    city: data['city'],
                    district: data['district'],
                  );
                  final incomplete = DisplayNameUtils.isProfileIncomplete(data);
                  return ListTile(
                    title: Text(displayName),
                    subtitle: Text('Role: $roleLabel | $location'),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (incomplete)
                          const Chip(label: Text('Profile incomplete')),
                        if (doc.id == FirebaseAuth.instance.currentUser?.uid)
                          const Chip(label: Text('You')),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User & Service counts ──
          Text(
            'Users & Services',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CountCard(
                title: 'Total Users',
                stream: _MetricStreams.usersTotal,
              ),
              _CountCard(
                title: 'Providers',
                stream: _MetricStreams.usersProviders,
              ),
              _CountCard(title: 'Seekers', stream: _MetricStreams.usersSeekers),
              _CountCard(
                title: 'Pending Services',
                stream: _MetricStreams.servicesPending,
              ),
              _CountCard(
                title: 'Approved Services',
                stream: _MetricStreams.servicesApproved,
              ),
              _CountCard(
                title: 'Rejected Services',
                stream: _MetricStreams.servicesRejected,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bookings & Payments ──
          Text(
            'Bookings & Payments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CountCard(
                title: 'Total Bookings',
                stream: _MetricStreams.bookingsTotal,
              ),
              _CountCard(
                title: 'Payments',
                stream: _MetricStreams.paymentsTotal,
              ),
              _SumCard(
                title: 'Revenue (LKR)',
                stream: _MetricStreams.paymentsSuccess,
                field: 'amount',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Reviews ──
          Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CountCard(
                title: 'Total Reviews',
                stream: _MetricStreams.reviewsTotal,
              ),
              _AverageCard(
                title: 'Avg Rating',
                stream: _MetricStreams.reviewsTotal,
                field: 'rating',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Pending SLA overview ──
          Text(
            'Pending SLA Overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _SlaSummary(),
        ],
      ),
    );
  }
}

class _MetricStreams {
  static final usersTotal = FirestoreRefs.users().snapshots();
  static final usersProviders = FirestoreRefs.users()
      .where('role', whereIn: ['provider', 'Provider', 'Service Provider'])
      .snapshots();
  static final usersSeekers = FirestoreRefs.users()
      .where('role', isEqualTo: 'seeker')
      .snapshots();
  static final servicesPending = FirestoreRefs.services()
      .where('status', isEqualTo: 'pending')
      .snapshots();
  static final servicesApproved = FirestoreRefs.services()
      .where('status', isEqualTo: 'approved')
      .snapshots();
  static final servicesRejected = FirestoreRefs.services()
      .where('status', isEqualTo: 'rejected')
      .snapshots();
  static final bookingsTotal = FirestoreRefs.bookings().snapshots();
  static final paymentsTotal = FirestoreRefs.payments().snapshots();
  static final paymentsSuccess = FirestoreRefs.payments()
      .where('status', isEqualTo: 'success')
      .snapshots();
  static final reviewsTotal = FirestoreRefs.reviews().snapshots();
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.title, required this.stream});

  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    const Text('Error'),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.data?.docs.length ?? 0}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Card that sums a numeric field across all documents.
class _SumCard extends StatelessWidget {
  const _SumCard({
    required this.title,
    required this.stream,
    required this.field,
  });

  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String field;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              double total = 0;
              for (final doc in snapshot.data?.docs ?? []) {
                total += (doc.data()[field] ?? 0).toDouble();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    total.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Card that averages a numeric field across all documents.
class _AverageCard extends StatelessWidget {
  const _AverageCard({
    required this.title,
    required this.stream,
    required this.field,
  });

  final String title;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String field;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              double avg = 0;
              if (docs.isNotEmpty) {
                double sum = 0;
                int count = 0;
                for (final doc in docs) {
                  final v = doc.data()[field];
                  if (v != null) {
                    sum += (v as num).toDouble();
                    count++;
                  }
                }
                if (count > 0) avg = sum / count;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shows a breakdown of pending services by SLA bucket.
class _SlaSummary extends StatelessWidget {
  const _SlaSummary();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _MetricStreams.servicesPending,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        int under12h = 0;
        int under48h = 0;
        int over48h = 0;
        final now = DateTime.now();
        for (final doc in docs) {
          final ts = doc.data()['createdAt'] as Timestamp?;
          if (ts == null) {
            over48h++;
            continue;
          }
          final hours = now.difference(ts.toDate()).inHours;
          if (hours < 12) {
            under12h++;
          } else if (hours < 48) {
            under48h++;
          } else {
            over48h++;
          }
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _slaBucket(context, '< 12 hours', under12h, Colors.green),
            _slaBucket(context, '12–48 hours', under48h, Colors.orange),
            _slaBucket(context, '> 48 hours', over48h, Colors.red),
          ],
        );
      },
    );
  }

  Widget _slaBucket(
    BuildContext context,
    String label,
    int count,
    Color color,
  ) {
    return SizedBox(
      width: 180,
      child: Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 10, color: color),
                  const SizedBox(width: 6),
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
