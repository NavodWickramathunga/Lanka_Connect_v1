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

class _UsersPanel extends StatelessWidget {
  const _UsersPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.users().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load users: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No users found.'));
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
                  if (incomplete) const Chip(label: Text('Profile incomplete')),
                  if (doc.id == FirebaseAuth.instance.currentUser?.uid)
                    const Chip(label: Text('You')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _CountCard(title: 'Total Users', stream: _MetricStreams.usersTotal),
          _CountCard(title: 'Providers', stream: _MetricStreams.usersProviders),
          _CountCard(title: 'Seekers', stream: _MetricStreams.usersSeekers),
          _CountCard(
            title: 'Pending Services',
            stream: _MetricStreams.servicesPending,
          ),
          _CountCard(
            title: 'Approved Services',
            stream: _MetricStreams.servicesApproved,
          ),
          _CountCard(title: 'Bookings', stream: _MetricStreams.bookingsTotal),
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
  static final bookingsTotal = FirestoreRefs.bookings().snapshots();
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
