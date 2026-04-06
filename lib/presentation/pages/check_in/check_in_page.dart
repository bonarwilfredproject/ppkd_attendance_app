import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'package:ppkd_attendance_app/core/services/location_service.dart';
import 'package:ppkd_attendance_app/data/repositories/attendance_repository.dart';

/// Full-screen map + bottom-sheet Check-in page.
/// Navigate to this page for check-in, pass [isCheckOut: true] for check-out.
class CheckInPage extends StatefulWidget {
  final bool isCheckOut;
  const CheckInPage({super.key, this.isCheckOut = false});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  // ── state ────────────────────────────────────────────────
  LatLng? currentLatLng;
  String address = 'Mendapatkan lokasi...';
  String? checkInStatus; // from API / local state
  bool isLoading = true;
  bool isSubmitting = false;
  final TextEditingController noteC = TextEditingController();
  String? checkOutStatus;
  GoogleMapController? mapController;
  StreamSubscription<Position>? positionStream;
  Timer? _clockTimer;
  String _liveTime = DateFormat('hh:mm a').format(DateTime.now());

  final AttendanceRepository repo = AttendanceRepository();

  // ── init ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _startClock();
    _initLocation();
    _loadStatus();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _liveTime = DateFormat('hh:mm a').format(DateTime.now()));
    });
  }

  Future<void> _loadStatus() async {
    try {
      final res = await repo.getTodayAttendance();

      print("TODAY RESPONSE: $res");

      setState(() {
        checkInStatus = res['data']?['check_in_time'];
        checkOutStatus = res['data']?['check_out_time']; // 🔥 TAMBAHIN
      });
    } catch (e) {
      print("ERROR LOAD STATUS: $e");
    }
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      final latLng = LatLng(pos.latitude, pos.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final place = placemarks.first;
      final addr =
          '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';

      setState(() {
        currentLatLng = latLng;
        address = addr;
        isLoading = false;
      });

      // Start live tracking
      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            final newLatLng = LatLng(pos.latitude, pos.longitude);
            setState(() => currentLatLng = newLatLng);
            mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
          });
    } catch (e) {
      setState(() {
        address = 'Gagal mendapatkan lokasi';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _clockTimer?.cancel();
    noteC.dispose();
    super.dispose();
  }

  String _buildStatusText() {
    // ── CHECK IN PAGE ──
    if (!widget.isCheckOut) {
      if (checkInStatus == null) {
        return 'Belum Check in';
      } else {
        return 'Sudah Check in';
      }
    }

    // ── CHECK OUT PAGE ──
    if (checkOutStatus == null) {
      return 'Belum Check out';
    } else {
      return 'Sudah Check out';
    }
  }

  // ── action ────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (currentLatLng == null) return;
    setState(() => isSubmitting = true);

    try {
      final pos = await LocationService.getCurrentLocation();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final place = placemarks.first;
      final addr = "${place.street}, ${place.locality}, ${place.country}";

      dynamic res;
      if (widget.isCheckOut) {
        res = await repo.checkOut(pos.latitude, pos.longitude, addr);
      } else {
        res = await repo.checkIn(pos.latitude, pos.longitude, addr);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ??
                (widget.isCheckOut
                    ? 'Absen pulang berhasil'
                    : 'Absen masuk berhasil'),
          ),
        ),
      );

      await _loadStatus(); // 🔥 refresh dulu
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }

    setState(() => isSubmitting = false);
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final label = widget.isCheckOut ? 'Check out' : 'Check in';

    return Scaffold(
      backgroundColor: const Color(0xFFD4E600),
      body: Stack(
        children: [
          // ── full-screen map ──
          Positioned.fill(
            child: currentLatLng == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (c) {
                      mapController = c;
                      mapController?.animateCamera(
                        CameraUpdate.newLatLng(currentLatLng!),
                      );
                    },
                    initialCameraPosition: CameraPosition(
                      target: currentLatLng!,
                      zoom: 17,
                    ),
                    markers: {
                      if (currentLatLng != null)
                        Marker(
                          markerId: const MarkerId('me'),
                          position: currentLatLng!,
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
          ),

          // ── live clock overlay (top center) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  // back button
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _liveTime,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // refresh button
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: _initLocation,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── bottom sheet ──
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.35,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // drag handle
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // title
                        Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF5B7BFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.black87,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  isLoading
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          address,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                            height: 1.5,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // note
                        Row(
                          children: [
                            const Icon(
                              Icons.notes,
                              color: Colors.black54,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: noteC,
                                decoration: const InputDecoration(
                                  hintText: 'Note(Optional)',
                                  hintStyle: TextStyle(
                                    color: Colors.black38,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // status
                        Row(
                          children: [
                            const Text(
                              'Status : ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _buildStatusText(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5B7BFF),
                              disabledBackgroundColor: const Color(
                                0xFF5B7BFF,
                              ).withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ── bottom nav ──
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.access_time_outlined, 'label': 'History'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    return Container(
      decoration: const BoxDecoration(color: Color(0xFFD4E600)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              return GestureDetector(
                onTap: () {
                  if (i == 0)
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  if (i == 2) Navigator.pushNamed(context, '/history');
                  if (i == 3) Navigator.pushNamed(context, '/profile');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: const Color(0xFF5B7BFF),
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: const TextStyle(
                        color: Color(0xFF5B7BFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
