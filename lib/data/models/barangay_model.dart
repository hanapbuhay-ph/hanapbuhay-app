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

  // IDs match the `barangays` table in the backend database (verified via
  // `php artisan tinker`). Names and coordinates are for Trinidad, Bohol.
  static List<Barangay> trinidadBarangays = [
    Barangay(id: '1',  name: 'Banlasan',            center: const LatLng(9.9321, 124.3654)),
    Barangay(id: '2',  name: 'Bongbong',             center: const LatLng(9.9456, 124.3821)),
    Barangay(id: '3',  name: 'Catoogan',             center: const LatLng(9.9512, 124.3312)),
    Barangay(id: '4',  name: 'Guinobatan',           center: const LatLng(9.9678, 124.3543)),
    Barangay(id: '5',  name: 'Hinlayagan Ilaud',     center: const LatLng(9.9823, 124.3122)),
    Barangay(id: '6',  name: 'Hinlayagan Ilaya',     center: const LatLng(9.9712, 124.3211)),
    Barangay(id: '7',  name: 'Kauswagan',            center: const LatLng(9.9634, 124.3421)),
    Barangay(id: '8',  name: 'Kinan-oan',            center: const LatLng(9.9912, 124.3411)),
    Barangay(id: '9',  name: 'La Union',             center: const LatLng(9.9145, 124.3511)),
    Barangay(id: '10', name: 'La Victoria',          center: const LatLng(9.9234, 124.3912)),
    Barangay(id: '11', name: 'Mabuhay Cabigohan',    center: const LatLng(9.9112, 124.3721)),
    Barangay(id: '12', name: 'Mahagbu',              center: const LatLng(9.9412, 124.4012)),
    Barangay(id: '13', name: 'Manuel M. Roxas',      center: const LatLng(9.9567, 124.3611)),
    Barangay(id: '14', name: 'Poblacion',            center: const LatLng(9.9575, 124.3517)),
    Barangay(id: '15', name: 'San Isidro',           center: const LatLng(9.9312, 124.3121)),
    Barangay(id: '16', name: 'San Vicente',          center: const LatLng(9.9212, 124.3221)),
    Barangay(id: '17', name: 'Santo Tomas',          center: const LatLng(9.9723, 124.3712)),
    Barangay(id: '18', name: 'Soom',                 center: const LatLng(9.9612, 124.3012)),
    Barangay(id: '19', name: 'Tagum Norte',          center: const LatLng(9.9923, 124.3611)),
    Barangay(id: '20', name: 'Tagum Sur',            center: const LatLng(9.9823, 124.3511)),
  ];
}
