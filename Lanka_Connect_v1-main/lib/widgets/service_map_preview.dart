import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

class ServiceMapPreview extends StatelessWidget {
  const ServiceMapPreview({
    super.key,
    required this.point,
    this.title = '',
    this.height = 180,
    this.onTap,
  });

  final LatLng point;
  final String title;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gmPoint = gm.LatLng(point.latitude, point.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: AbsorbPointer(
            child: gm.GoogleMap(
              initialCameraPosition: gm.CameraPosition(
                target: gmPoint,
                zoom: 14,
              ),
              markers: {
                gm.Marker(
                  markerId: const gm.MarkerId('preview'),
                  position: gmPoint,
                  infoWindow: gm.InfoWindow(title: title),
                ),
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ),
        ),
      ),
    );
  }
}
