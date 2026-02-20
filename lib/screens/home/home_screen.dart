import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/theme/app_theme_controller.dart';
import '../../ui/web/web_shell.dart';
import '../../utils/demo_data_service.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/firebase_env.dart';
import '../../utils/notification_service.dart';
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
  String? _webRouteId;
  bool _seeding = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  final Set<String> _seenNotificationIds = <String>{};
  String? _notificationKey;
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

  void _setWebRoute(String routeId) {
    setState(() {
      _webRouteId = routeId;
    });
  }

  String _roleLabel(String role) {
    if (role == UserRoles.provider) return 'Provider';
    if (role == UserRoles.admin) return 'Admin';
    return 'Seeker';
  }

  Query<Map<String, dynamic>> _notificationQuery({
    required String uid,
    required String role,
  }) {
    if (role == UserRoles.admin) {
      return FirestoreRefs.notifications().where(
        'recipientId',
        whereIn: [uid, NotificationService.adminChannelRecipientId],
      );
    }
    return FirestoreRefs.notifications().where('recipientId', isEqualTo: uid);
  }

  List<WebShellNavItem> _webNavItemsForRole(String role) {
    if (role == UserRoles.admin) {
      return const [
        WebShellNavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.space_dashboard,
        ),
        WebShellNavItem(
          id: 'moderation',
          label: 'Moderation',
          icon: Icons.verified_user,
        ),
        WebShellNavItem(
          id: 'services',
          label: 'Services',
          icon: Icons.storefront,
        ),
        WebShellNavItem(id: 'profile', label: 'Profile', icon: Icons.person),
      ];
    }

    if (role == UserRoles.provider) {
      return const [
        WebShellNavItem(id: 'my-services', label: 'My Services', icon: Icons.store),
        WebShellNavItem(
          id: 'bookings',
          label: 'Bookings',
          icon: Icons.calendar_today,
        ),
        WebShellNavItem(id: 'chat', label: 'Chat', icon: Icons.chat),
        WebShellNavItem(id: 'profile', label: 'Profile', icon: Icons.person),
      ];
    }

    return const [
      WebShellNavItem(id: 'services', label: 'Services', icon: Icons.search),
      WebShellNavItem(
        id: 'bookings',
        label: 'Bookings',
        icon: Icons.calendar_today,
      ),
      WebShellNavItem(id: 'chat', label: 'Chat', icon: Icons.chat),
      WebShellNavItem(id: 'profile', label: 'Profile', icon: Icons.person),
    ];
  }

  Map<String, Widget> _webRouteMapForRole(String role) {
    if (role == UserRoles.admin) {
      return const {
        'dashboard': AdminWebDashboardScreen(),
        'moderation': AdminServicesScreen(),
        'services': ServiceListScreen(),
        'profile': ProfileScreen(),
      };
    }

    if (role == UserRoles.provider) {
      return const {
        'my-services': ServiceListScreen(showOnlyMine: true),
        'bookings': BookingListScreen(),
        'chat': ChatListScreen(),
        'profile': ProfileScreen(),
      };
    }

    return const {
      'services': ServiceListScreen(),
      'bookings': BookingListScreen(),
      'chat': ChatListScreen(),
      'profile': ProfileScreen(),
    };
  }

  Widget _notificationAction(String uid, String role) {
    final iconColor = kIsWeb ? null : Colors.white;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationQuery(uid: uid, role: role).snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs
                .where((doc) => (doc.data()['isRead'] ?? false) != true)
                .length ??
            0;
        final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';
        return IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications, color: iconColor),
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

  void _ensureNotificationSubscription(String uid, String role) {
    final key = '$uid|$role';
    if (_notificationKey == key && _notificationSubscription != null) {
      return;
    }

    _notificationSubscription?.cancel();
    _notificationKey = key;
    _notificationPrimed = false;
    _seenNotificationIds.clear();

    _notificationSubscription = _notificationQuery(uid: uid, role: role)
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
        }, onError: (Object error, StackTrace stackTrace) {
          debugPrint('Notification stream error: $error');
          debugPrint(stackTrace.toString());
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
      final created = (result['created'] ?? 0).toString();
      final updated = (result['updated'] ?? 0).toString();
      final skipped = (result['skipped'] ?? 0).toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Demo data seeded. Created: $created, Updated: $updated, Skipped: $skipped.'
                : 'Seeder finished with partial result.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessageForOperation(
          e,
          operation: 'seed_demo_data',
        ),
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
      _notificationKey = null;
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

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
        _ensureNotificationSubscription(user.uid, role);

        final tabs = _tabsForRole(role);
        final items = _navItemsForRole(role);
        final selectedIndex = _currentIndex.clamp(0, tabs.length - 1);
        final webRouteMap = _webRouteMapForRole(role);
        final webNavItems = _webNavItemsForRole(role);

        if (_webRouteId == null || !webRouteMap.containsKey(_webRouteId)) {
          _webRouteId = webNavItems.first.id;
        }

        if (kIsWeb) {
          final routeId = _webRouteId!;
          final routeWidget = webRouteMap[routeId]!;
          final routeLabel =
              webNavItems
                  .firstWhere((item) => item.id == routeId)
                  .label;
          return WebShell(
            appTitle: 'Lanka Connect',
            navItems: webNavItems,
            currentId: routeId,
            onSelect: _setWebRoute,
            pageTitle: routeLabel,
            pageSubtitle:
                '${_roleLabel(role)}${user.email != null ? ' | ${user.email}' : ''} | Backend: ${FirebaseEnv.backendLabel()}',
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) {
                  return IconButton(
                    onPressed: AppThemeController.toggleTheme,
                    tooltip: mode == ThemeMode.dark
                        ? 'Switch to light theme'
                        : 'Switch to dark theme',
                    icon: Icon(
                      mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                    ),
                  );
                },
              ),
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
              _notificationAction(user.uid, role),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
              ),
            ],
            child: routeWidget,
          );
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    RoleVisuals.forRole(role).accent,
                    MobileTokens.primary,
                  ],
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Lanka Connect', style: TextStyle(color: Colors.white)),
                Text(
                  '${_roleLabel(role)}${user.email != null ? ' | ${user.email}' : ''} | Backend: ${FirebaseEnv.backendLabel()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: const Color(0xFFE7F3FF)),
                ),
              ],
            ),
            actions: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) {
                  return IconButton(
                    onPressed: AppThemeController.toggleTheme,
                    tooltip: mode == ThemeMode.dark
                        ? 'Switch to light theme'
                        : 'Switch to dark theme',
                    icon: Icon(
                      mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                    ),
                  );
                },
              ),
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
              _notificationAction(user.uid, role),
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(selectedIndex), child: tabs[selectedIndex]),
          ),
          floatingActionButton: _fabForRole(role, selectedIndex),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _setIndex,
            indicatorColor: RoleVisuals.forRole(role).chipBackground,
            destinations: items
                .map(
                  (item) => NavigationDestination(
                    icon: item.icon,
                    label: item.label ?? '',
                  ),
                )
                .toList(),
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
