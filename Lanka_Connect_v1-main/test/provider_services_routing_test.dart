import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/screens/provider/provider_services_screen.dart';
import 'package:lanka_connect/screens/services/service_list_screen.dart';
import 'package:lanka_connect/ui/mobile/mobile_routes.dart';
import 'package:lanka_connect/utils/user_roles.dart';

void main() {
  testWidgets('provider services route resolves to ProviderServicesScreen', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final providerRoutes = MobileRoutes.forRole(UserRoles.provider);
    final servicesRoute = providerRoutes.firstWhere(
      (route) => route.id == MobileAppRouteId.services,
    );
    final widget = servicesRoute.builder(context);
    expect(widget, isA<ProviderServicesScreen>());
  });

  testWidgets('seeker/admin services routes are not ProviderServicesScreen', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final seekerRoutes = MobileRoutes.forRole(UserRoles.seeker);
    final adminRoutes = MobileRoutes.forRole(UserRoles.admin);

    final seekerServices = seekerRoutes.firstWhere(
      (route) => route.id == MobileAppRouteId.services,
    );
    final adminServices = adminRoutes.firstWhere(
      (route) => route.id == MobileAppRouteId.services,
    );

    expect(seekerServices.builder(context), isA<ServiceListScreen>());
    expect(adminServices.builder(context), isA<ServiceListScreen>());
    expect(
      seekerServices.builder(context),
      isNot(isA<ProviderServicesScreen>()),
    );
    expect(
      adminServices.builder(context),
      isNot(isA<ProviderServicesScreen>()),
    );
  });
}
