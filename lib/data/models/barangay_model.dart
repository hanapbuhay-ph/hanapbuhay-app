import 'package:google_maps_flutter/google_maps_flutter.dart';

class Barangay {
  final String id;
  final String name;
  final LatLng center;

  Barangay({
    required this.id,
    required this.name,
    required this.center,
  });

  static List<Barangay> trinidadBarangays = [
    Barangay(id: 'b1', name: 'Abachanan', center: const LatLng(9.9145, 124.3411)),
    Barangay(id: 'b2', name: 'Banlasan', center: const LatLng(9.9321, 124.3654)),
    Barangay(id: 'b3', name: 'Bongbong', center: const LatLng(9.9456, 124.3821)),
    Barangay(id: 'b4', name: 'Catoogan', center: const LatLng(9.9512, 124.3312)),
    Barangay(id: 'b5', name: 'Guinobatan', center: const LatLng(9.9678, 124.3543)),
    Barangay(id: 'b6', name: 'Hinlayagan Centro', center: const LatLng(9.9712, 124.3211)),
    Barangay(id: 'b7', name: 'Hinlayagan Ilaud', center: const LatLng(9.9823, 124.3122)),
    Barangay(id: 'b8', name: 'Kinan-oan', center: const LatLng(9.9912, 124.3411)),
    Barangay(id: 'b9', name: 'La Victoria', center: const LatLng(9.9234, 124.3912)),
    Barangay(id: 'b10', name: 'Mabuhay Cabigohan', center: const LatLng(9.9112, 124.3721)),
    Barangay(id: 'b11', name: 'Mahagbu', center: const LatLng(9.9412, 124.4012)),
    Barangay(id: 'b12', name: 'Manuel M. Roxas', center: const LatLng(9.9567, 124.3611)),
    Barangay(id: 'b13', name: 'Poblacion', center: const LatLng(9.9575, 124.3517)),
    Barangay(id: 'b14', name: 'Puerto San Pedro', center: const LatLng(9.9723, 124.3712)),
    Barangay(id: 'b15', name: 'Quinicotogan', center: const LatLng(9.9812, 124.3811)),
    Barangay(id: 'b16', name: 'San Isidro', center: const LatLng(9.9312, 124.3121)),
    Barangay(id: 'b17', name: 'San Vicente', center: const LatLng(9.9212, 124.3221)),
    Barangay(id: 'b18', name: 'Soledad', center: const LatLng(9.9612, 124.3012)),
    Barangay(id: 'b19', name: 'Tagum Norte', center: const LatLng(9.9923, 124.3611)),
    Barangay(id: 'b20', name: 'Tagum Sur', center: const LatLng(9.9823, 124.3511)),
  ];
}
