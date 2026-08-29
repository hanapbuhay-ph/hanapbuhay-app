import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';

class LiveTrackingMap extends StatefulWidget {
  final LatLng clientLocation;
  final LatLng workerLocation;
  final bool isTracking;
  final VoidCallback? onArrival;

  const LiveTrackingMap({
    Key? key,
    required this.clientLocation,
    required this.workerLocation,
    this.isTracking = false,
    this.onArrival,
  }) : super(key: key);

  @override
  State<LiveTrackingMap> createState() => LiveTrackingMapState();
}

class LiveTrackingMapState extends State<LiveTrackingMap> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _simulatedWorkerPos;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _simulatedWorkerPos = widget.workerLocation;
    if (widget.isTracking) {
      _startSimulation();
    }
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTracking && !oldWidget.isTracking) {
      _startSimulation();
    } else if (!widget.isTracking && oldWidget.isTracking) {
      _timer?.cancel();
    }
  }

  void _startSimulation() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.01; // Reach in 10 seconds
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          widget.onArrival?.call();
        }
        
        final lat = widget.workerLocation.latitude + (widget.clientLocation.latitude - widget.workerLocation.latitude) * _progress;
        final lng = widget.workerLocation.longitude + (widget.clientLocation.longitude - widget.workerLocation.longitude) * _progress;
        _simulatedWorkerPos = LatLng(lat, lng);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void centerMap() async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(widget.clientLocation, 14));
  }

  @override
  Widget build(BuildContext context) {
    final markers = {
      Marker(
        markerId: const MarkerId('client'),
        position: widget.clientLocation,
        infoWindow: const InfoWindow(title: 'Service Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('worker'),
        position: _simulatedWorkerPos ?? widget.workerLocation,
        infoWindow: const InfoWindow(title: 'Worker'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.clientLocation,
        zoom: 14, // Slightly closer default
      ),
      markers: markers,
      onMapCreated: (controller) => _controller.complete(controller),
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      myLocationButtonEnabled: false,
      polylines: {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.workerLocation, widget.clientLocation],
          color: AppColors.primary.withOpacity(0.3),
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      },
    );
  }
}
