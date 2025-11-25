import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Palet warna sederhana & konsisten
const Color kPrimary = Color(0xFF2563EB);
const Color kBg = Color(0xFFF3F4F6);
const Color kCard = Colors.white;
const Color kTextMain = Color(0xFF111827);
const Color kTextMuted = Color(0xFF6B7280);

// Model data apotek
class PharmacyData {
  final String name;
  final String address;
  final String phone;
  final String hours;
  final String info;
  final IconData icon;
  final LatLng location;

  PharmacyData({
    required this.name,
    required this.address,
    required this.phone,
    required this.hours,
    required this.info,
    required this.icon,
    required this.location,
  });
}

class LokasiPage extends StatefulWidget {
  const LokasiPage({super.key});

  @override
  State<LokasiPage> createState() => _LokasiPageState();
}

class _LokasiPageState extends State<LokasiPage> {
  Position? _currentPosition;
  bool _isLoading = false;
  final MapController _mapController = MapController();
  List<PharmacyData> _pharmacies = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.location_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Layanan lokasi belum aktif'),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.warning_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Izin lokasi ditolak'),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error_outline_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Izin lokasi permanen ditolak'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      // Dapatkan lokasi pertama kali
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _pharmacies = _generatePharmacies(position);
          _isLoading = false;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }

      // Mulai tracking real-time
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update setiap 10 meter
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen((Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                _pharmacies = _generatePharmacies(position);
              });
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                15.0,
              );
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPharmacyDetail(PharmacyData pharmacy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(pharmacy.icon, color: kPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kTextMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pharmacy.info,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.location_on_rounded, pharmacy.address),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_rounded, pharmacy.phone),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.access_time_rounded, pharmacy.hours),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kTextMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: kTextMain),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.location_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Layanan lokasi belum aktif'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Izin lokasi ditolak'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Izin lokasi permanen ditolak'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _pharmacies = _generatePharmacies(position);
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Lokasi berhasil ditemukan'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<PharmacyData> _generatePharmacies(Position position) {
    return [
      PharmacyData(
        name: 'Apotek Sehat',
        address: 'Jl. Sehat Raya No. 12, Kec. Makmur',
        phone: '(021) 5551234',
        hours: 'Buka 24 jam',
        info: 'Buka 24 jam',
        icon: Icons.local_pharmacy_rounded,
        location: LatLng(position.latitude + 0.001, position.longitude + 0.001),
      ),
      PharmacyData(
        name: 'Apotek Mandiri',
        address: 'Jl. Mandiri No. 45, Kec. Makmur',
        phone: '(021) 5555678',
        hours: '08.00 - 22.00 WIB',
        info: 'Tutup 22.00',
        icon: Icons.medication_rounded,
        location: LatLng(
          position.latitude - 0.0012,
          position.longitude - 0.0008,
        ),
      ),
      PharmacyData(
        name: 'Apotek Prima',
        address: 'Jl. Prima Utama No. 89, Kec. Makmur',
        phone: '(021) 5559012',
        hours: '07.00 - 21.00 WIB',
        info: 'Diskon 20%',
        icon: Icons.storefront_rounded,
        location: LatLng(
          position.latitude + 0.0008,
          position.longitude - 0.001,
        ),
      ),
      PharmacyData(
        name: 'Apotek Family',
        address: 'Jl. Keluarga Sejahtera No. 23, Kec. Makmur',
        phone: '(021) 5553456',
        hours: '08.00 - 20.00 WIB',
        info: 'Gratis ongkir',
        icon: Icons.health_and_safety_rounded,
        location: LatLng(
          position.latitude - 0.0005,
          position.longitude + 0.0015,
        ),
      ),
      PharmacyData(
        name: 'Apotek Kimia',
        address: 'Jl. Kimia Farma No. 67, Kec. Makmur',
        phone: '(021) 5557890',
        hours: '08.00 - 19.00 WIB',
        info: 'Buka 08.00',
        icon: Icons.science_rounded,
        location: LatLng(
          position.latitude + 0.0015,
          position.longitude - 0.0005,
        ),
      ),
      PharmacyData(
        name: 'Apotek Bersama',
        address: 'Jl. Bersama No. 34, Kec. Makmur',
        phone: '(021) 5552345',
        hours: '07.30 - 21.30 WIB',
        info: 'Konsultasi gratis',
        icon: Icons.medication_liquid_rounded,
        location: LatLng(
          position.latitude - 0.0008,
          position.longitude + 0.0012,
        ),
      ),
      PharmacyData(
        name: 'Apotek Sentosa',
        address: 'Jl. Sentosa Jaya No. 56, Kec. Makmur',
        phone: '(021) 5556789',
        hours: '08.00 - 22.00 WIB',
        info: 'Lengkap & murah',
        icon: Icons.local_hospital_rounded,
        location: LatLng(
          position.latitude + 0.0003,
          position.longitude + 0.0018,
        ),
      ),
      PharmacyData(
        name: 'Apotek Cahaya',
        address: 'Jl. Cahaya No. 78, Kec. Makmur',
        phone: '(021) 5554321',
        hours: '08.00 - 20.00 WIB',
        info: 'Tutup 20.00',
        icon: Icons.medical_services_rounded,
        location: LatLng(
          position.latitude - 0.0015,
          position.longitude - 0.0003,
        ),
      ),
      PharmacyData(
        name: 'Apotek Harapan',
        address: 'Jl. Harapan Indah No. 90, Kec. Makmur',
        phone: '(021) 5558765',
        hours: '07.00 - 21.00 WIB',
        info: 'Diskon 15%',
        icon: Icons.vaccines_rounded,
        location: LatLng(
          position.latitude + 0.0013,
          position.longitude + 0.0008,
        ),
      ),
      PharmacyData(
        name: 'Apotek Sejahtera',
        address: 'Jl. Sejahtera No. 12A, Kec. Makmur',
        phone: '(021) 5551098',
        hours: '08.00 - 21.00 WIB',
        info: 'Delivery cepat',
        icon: Icons.local_pharmacy_rounded,
        location: LatLng(
          position.latitude - 0.0003,
          position.longitude - 0.0014,
        ),
      ),
    ];
  }

  List<Marker> _buildMarkers() {
    if (_currentPosition == null) return [];

    final markers = <Marker>[
      // Marker lokasi pengguna
      Marker(
        width: 40,
        height: 40,
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        child: _UserLocationMarker(),
      ),
    ];

    // Tambahkan marker untuk setiap apotek
    for (int i = 0; i < _pharmacies.length; i++) {
      final pharmacy = _pharmacies[i];
      markers.add(
        Marker(
          width: 80,
          height: 70,
          point: pharmacy.location,
          child: GestureDetector(
            onTap: () => _showPharmacyDetail(pharmacy),
            child: _buildPharmacyMarker(
              name: pharmacy.name,
              info: pharmacy.info,
              icon: pharmacy.icon,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildPharmacyMarker({
    required String name,
    required String info,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(color: kCard, shape: BoxShape.circle),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kTextMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                info,
                style: const TextStyle(fontSize: 8, color: kTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: _currentPosition == null ? _buildEmptyState() : _buildMapView(),
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: kPrimary,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // icon circle
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFE5EDFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 40,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Temukan apotek terdekat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextMain,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Aktifkan lokasi untuk melihat apotek di sekitar Anda.',
              style: TextStyle(fontSize: 13, color: kTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
                label: Text(
                  _isLoading ? 'Mencari lokasi...' : 'Gunakan lokasi saya',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final markers = _buildMarkers();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tugasakhir',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        // card info di atas map
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kCard.withOpacity(0.96),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_pharmacy_rounded,
                  size: 18,
                  color: kPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${markers.length - 1} apotek ditemukan di sekitar Anda',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextMain,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Marker lokasi user yang simple & clean
class _UserLocationMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: kPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
