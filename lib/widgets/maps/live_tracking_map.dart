import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';

class LiveTrackingMap extends StatefulWidget {
  /// Static fallback positions (barangay centers) shown before live GPS kicks in.
  final LatLng clientLocation;
  final LatLng workerLocation;

  /// Live GPS overrides — when non-null these replace the static pins.
  final LatLng? liveClientLocation;
  final LatLng? liveWorkerLocation;

  const LiveTrackingMap({
    super.key,
    required this.clientLocation,
    required this.workerLocation,
    this.liveClientLocation,
    this.liveWorkerLocation,
  });

  @override
  State<LiveTrackingMap> createState() => LiveTrackingMapState();
}

class LiveTrackingMapState extends State<LiveTrackingMap> {
  final Completer<GoogleMapController> _controller = Completer();

  void centerMap() async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        widget.liveClientLocation ?? widget.clientLocation,
        14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientPos = widget.liveClientLocation ?? widget.clientLocation;
    final workerPos = widget.liveWorkerLocation ?? widget.workerLocation;

    final markers = {
      Marker(
        markerId: const MarkerId('client'),
        position: clientPos,
        infoWindow: const InfoWindow(title: 'Client'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('worker'),
        position: workerPos,
        infoWindow: const InfoWindow(title: 'Worker'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: clientPos, zoom: 14),
      markers: markers,
      onMapCreated: (c) => _controller.complete(c),
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      myLocationButtonEnabled: false,
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [workerPos, clientPos],
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      },
    );
  }
}
