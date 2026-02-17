import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/demo_data_service.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/firebase_env.dart';
import '../../utils/user_roles.dart';
import '../admin/admin_web_dashboard_screen.dart';
import '../admin/admin_services_screen.dart';
import '../bookings/booking_list_screen.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../services/service_form_screen.dart';
import '../services/service_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _seeding = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  final Set<String> _seenNotificationIds = <String>{};
  String? _notificationUserId;
  bool _notificationPrimed = false;

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _roleLabel(String role) {
    if (role == UserRoles.provider) return 'Provider';
    if (role == UserRoles.admin) return 'Admin';
    return 'Seeker';
  }

  Widget _notificationAction(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.notifications()
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;
        final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
        return IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _ensureNotificationSubscription(String uid) {
    if (_notificationUserId == uid && _notificationSubscription != null) {
      return;
    }

    _notificationSubscription?.cancel();
    _notificationUserId = uid;
    _notificationPrimed = false;
    _seenNotificationIds.clear();

    _notificationSubscription = FirestoreRefs.notifications()
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
          if (!mounted || snapshot.docs.isEmpty) return;

          if (!_notificationPrimed) {
            for (final doc in snapshot.docs) {
              _seenNotificationIds.add(doc.id);
            }
            _notificationPrimed = true;
            return;
          }

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final isRead = (data['isRead'] ?? false) == true;
            if (isRead || _seenNotificationIds.contains(doc.id)) {
              continue;
            }
            _seenNotificationIds.add(doc.id);
            final title = (data['title'] ?? 'Notification').toString();
            final body = (data['body'] ?? '').toString();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
            );
            break;
          }
        });
  }

  Future<void> _seedDemoData() async {
    if (_seeding) return;

    setState(() {
      _seeding = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Seeding demo data...')));

    try {
      final result = await DemoDataService.seed();
      final ok = (result['ok'] ?? false) == true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Demo data seeded. Refresh tabs to view records.'
                : 'Seeder finished with partial result.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _seeding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _notificationUserId = null;
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    _ensureNotificationSubscription(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.users().doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data?.data() ?? {};
        final role = UserRoles.normalize(data['role']);

        final tabs = _tabsForRole(role);
        final items = _navItemsForRole(role);
        final selectedIndex = _currentIndex.clamp(0, tabs.length - 1);
        final useWebAdminShell = kIsWeb && role == UserRoles.admin;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lanka Connect'),
                Text(
                  '${_roleLabel(role)}${user.email != null ? ' | ${user.email}' : ''} | Backend: ${FirebaseEnv.backendLabel()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (role == UserRoles.admin)
                IconButton(
                  onPressed: _seeding ? null : _seedDemoData,
                  icon: _seeding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.dataset),
                  tooltip: 'Seed demo data',
                ),
              _notificationAction(user.uid),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: useWebAdminShell
              ? const AdminWebDashboardScreen()
              : tabs[selectedIndex],
          floatingActionButton: useWebAdminShell
              ? null
              : _fabForRole(role, selectedIndex),
          bottomNavigationBar: useWebAdminShell
              ? null
              : BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: _setIndex,
                  items: items,
                  type: BottomNavigationBarType.fixed,
                ),
        );
      },
    );
  }

  List<Widget> _tabsForRole(String role) {
    if (role == UserRoles.admin) {
      return const [
        AdminServicesScreen(),
        ServiceListScreen(),
        ProfileScreen(),
      ];
    }

    if (role == UserRoles.provider) {
      return const [
        ServiceListScreen(showOnlyMine: true),
        BookingListScreen(),
        ChatListScreen(),
        ProfileScreen(),
      ];
    }

    return const [
      ServiceListScreen(),
      BookingListScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _navItemsForRole(String role) {
    if (role == UserRoles.admin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'Moderate',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.storefront),
          label: 'Services',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    if (role == UserRoles.provider) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'My Services'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Services'),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Bookings',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  FloatingActionButton? _fabForRole(String role, int index) {
    if (role == UserRoles.provider && index == 0) {
      return FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ServiceFormScreen())),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
}
