import 'dart:math' show cos, sqrt, asin, sin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceUtils {
  DistanceUtils._();

  static double calculateDistance(LatLng loc1, LatLng loc2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((loc2.latitude - loc1.latitude) * p) / 2 +
        c(loc1.latitude * p) * c(loc2.latitude * p) *
            (1 - c((loc2.longitude - loc1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }
}
