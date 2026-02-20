import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../ui/web/web_page_scaffold.dart';

class ServiceMapItem {
  const ServiceMapItem({
    required this.serviceId,
    required this.title,
    required this.locationLabel,
    required this.priceLabel,
    required this.point,
    this.isApproximate = false,
    this.pointSource,
  });

  final String serviceId;
  final String title;
  final String locationLabel;
  final String priceLabel;
  final LatLng point;
  final bool isApproximate;
  final String? pointSource;
}

class ServiceMapScreen extends StatefulWidget {
  const ServiceMapScreen({super.key, required this.items, this.initialCenter});

  final List<ServiceMapItem> items;
  final LatLng? initialCenter;

  @override
  State<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends State<ServiceMapScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      if (kIsWeb) {
        return const WebPageScaffold(
          title: 'Service Map',
          subtitle: 'Map view of services by location data.',
          useScaffold: true,
          child: Center(
            child: Text(
              'No mappable locations found. Add city/district or coordinates to view services on map.',
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Service Map')),
        body: const Center(
          child: Text(
            'No mappable locations found. Add city/district or coordinates to view services on map.',
          ),
        ),
      );
    }

    final selected = widget.items[_selectedIndex];
    final center = widget.initialCenter ?? selected.point;
    final isWide = MediaQuery.of(context).size.width >= 900;

    final body = isWide
        ? Row(
            children: [
              Expanded(child: _mapPanel(center)),
              SizedBox(width: 360, child: _listPanel()),
            ],
          )
        : Column(
            children: [
              Expanded(flex: 3, child: _mapPanel(center)),
              Expanded(flex: 2, child: _listPanel()),
            ],
          );

    if (kIsWeb) {
      return WebPageScaffold(
        title: 'Service Map',
        subtitle: 'Map view of services by location data.',
        useScaffold: true,
        child: body,
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Service Map')), body: body);
  }

  Widget _mapPanel(LatLng center) {
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 11),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.lankaconnect.app',
        ),
        MarkerLayer(
          markers: [
            for (var i = 0; i < widget.items.length; i++)
              Marker(
                width: 42,
                height: 42,
                point: widget.items[i].point,
                child: IconButton(
                  tooltip: widget.items[i].title,
                  icon: Icon(
                    Icons.location_pin,
                    size: i == _selectedIndex ? 38 : 32,
                    color: i == _selectedIndex ? Colors.red : Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = i;
                    });
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _listPanel() {
    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = index == _selectedIndex;
        return ListTile(
          selected: isSelected,
          title: Text(item.title),
          subtitle: Text(
            item.isApproximate
                ? '${item.locationLabel}\n${item.priceLabel} (${item.pointSource ?? 'Approximate location'})'
                : '${item.locationLabel}\n${item.priceLabel}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            Navigator.of(context).pop(item.serviceId);
          },
        );
      },
    );
  }
}
