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
  // ── geofence constants ──────────────────────────────────
  static const bool _mockLocationForTesting =
      false; // 🔥 Set to FALSE when releasing app
  static const double _officeLat = -6.210731471676829;
  static const double _officeLng = 106.81299604066831;
  static const double _maxRadiusMeters = 60.0;
  static const String _officeName = 'PPKD Jakarta Pusat (Bendungan Hilir)';

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
  String? todayStatus;
  final AttendanceRepository repo = AttendanceRepository();
  bool get isCheckedIn => checkInStatus != null;
  bool get isCheckedOut => checkOutStatus != null;
  bool isStatusLoading = true;
  late DraggableScrollableController sheetController;
  double sheetSize = 0.52;
  double _distanceToOffice = double.infinity;
  bool get _isInRange => _distanceToOffice <= _maxRadiusMeters;

  /// Calculate distance from current position to the office
  void _updateDistance() {
    if (currentLatLng == null) return;
    _distanceToOffice = Geolocator.distanceBetween(
      currentLatLng!.latitude,
      currentLatLng!.longitude,
      _officeLat,
      _officeLng,
    );
  }

  // ── init ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    sheetController = DraggableScrollableController();

    sheetController.addListener(() {
      setState(() {
        sheetSize = sheetController.size;
      });
    });

    _startClock();
    _initLocation();

    Future.microtask(() async {
      await _loadStatus();
      setState(() {});
    });
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _liveTime = DateFormat('hh:mm a').format(DateTime.now()));
    });
  }

  Future<void> _loadStatus() async {
    try {
      final res = await repo.getTodayAttendance();

      setState(() {
        checkInStatus = res['data']?['check_in_time'];
        checkOutStatus = res['data']?['check_out_time'];
        todayStatus = res['data']?['status'];
        isStatusLoading = false; // 🔥 selesai load
      });
    } catch (e) {
      print("ERROR LOAD STATUS: $e");
      setState(() => isStatusLoading = false);
    }
  }

  bool get isCheckOutMode {
    if (todayStatus == 'izin') return false;

    if (checkInStatus != null && checkOutStatus == null) {
      return true; // 🔥 sudah check-in → harus check-out
    }

    return false; // default → check-in
  }

  Future<void> _initLocation() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      LatLng latLng = LatLng(pos.latitude, pos.longitude);

      if (_mockLocationForTesting) {
        latLng = const LatLng(_officeLat, _officeLng);
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      final place = placemarks.first;
      final addr =
          '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}';

      setState(() {
        currentLatLng = latLng;
        isLoading = false;
        _updateDistance();

        if (_isInRange) {
          address = '$_officeName\n$addr';
        } else {
          address = addr;
        }
      });

      // Animate map to the freshly acquired location
      if (mapController != null && currentLatLng != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(currentLatLng!));
      }

      // Start live tracking
      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((pos) async {
            LatLng newLatLng = LatLng(pos.latitude, pos.longitude);
            if (_mockLocationForTesting) {
              newLatLng = const LatLng(_officeLat, _officeLng);
            }
            setState(() {
              currentLatLng = newLatLng;
              _updateDistance();
            });
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
    if (todayStatus == 'izin') return 'Sedang Izin';

    if (checkInStatus == null) {
      return 'Belum Check in';
    }

    if (checkOutStatus == null) {
      return 'Sudah Check in (belum pulang)';
    }

    return 'Sudah Check out';
  }

  // ── action ────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (currentLatLng == null) return;

    // ── Geofence check ──────────────────────────────────
    _updateDistance();
    if (!_isInRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda berada ${_distanceToOffice.toStringAsFixed(0)}m dari $_officeName. '
            'Maksimal jarak ${_maxRadiusMeters.toInt()}m untuk absen.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final posLat = currentLatLng!.latitude;
      final posLng = currentLatLng!.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        posLat,
        posLng,
      );
      final place = placemarks.first;
      final addr = "${place.street}, ${place.locality}, ${place.country}";

      dynamic res;
      if (isCheckOutMode) {
        res = await repo.checkOut(posLat, posLng, addr);
      } else {
        res = await repo.checkIn(posLat, posLng, addr);
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
    final label = isStatusLoading
        ? 'Loading...'
        : isCheckedOut
        ? 'Selesai'
        : isCheckOutMode
        ? 'Check out'
        : 'Check in';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFD4E600),
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
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: const InfoWindow(title: "Posisi Saya"),
                        ),
                      // Office marker
                      Marker(
                        markerId: const MarkerId('office'),
                        position: const LatLng(_officeLat, _officeLng),
                        infoWindow: const InfoWindow(title: _officeName),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                      ),
                    },
                    circles: {
                      Circle(
                        circleId: const CircleId('geofence'),
                        center: const LatLng(_officeLat, _officeLng),
                        radius: _maxRadiusMeters,
                        fillColor: _isInRange
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.10),
                        strokeColor: _isInRange ? Colors.green : Colors.red,
                        strokeWidth: 2,
                      ),
                    },
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * sheetSize,
                    ),
                    myLocationEnabled: !_mockLocationForTesting,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
          ),

          // ── live clock overlay (top center) ──
          SafeArea(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(
                0,
                -(sheetSize - 0.35) * 50, // ✅ lebih natural
                0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // back button
                    Padding(
                      padding: const EdgeInsets.only(left: 8),

                      child: CircleAvatar(
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A2A) // dark surface
                            : Colors.white,
                        radius: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // refresh button
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        backgroundColor: isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                        radius: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: isDark ? Colors.white : Colors.black87,
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
          ),

          // ── zoom controls (right side) ──
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).size.height * sheetSize + 16,
            child: Column(
              children: [
                _buildZoomButton(
                  icon: Icons.add,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  isDark: isDark,
                  isTop: true,
                ),
                _buildZoomButton(
                  icon: Icons.remove,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  isDark: isDark,
                  isTop: false,
                ),
              ],
            ),
          ),

          // ── bottom sheet ──
          DraggableScrollableSheet(
            controller: sheetController,
            initialChildSize: 0.52,
            minChildSize: 0.40,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            // 🔥 HEADER (BACK - TIME - REFRESH)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),

                                  // drag handle
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // title
                        Center(
                          child: Text(
                            _liveTime,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
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
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                            height: 1.5,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── distance / geofence info ──
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isInRange
                                ? Colors.green.withOpacity(0.08)
                                : Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isInRange
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isInRange
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,
                                color: _isInRange ? Colors.green : Colors.red,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isInRange
                                          ? 'Dalam Jangkauan'
                                          : 'Di Luar Jangkauan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: _isInRange
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _distanceToOffice == double.infinity
                                          ? 'Menghitung jarak...'
                                          : 'Jarak: ${_distanceToOffice.toStringAsFixed(0)}m dari $_officeName '
                                                '(maks ${_maxRadiusMeters.toInt()}m)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // note
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: noteC,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Note(Optional)',
                                  hintStyle: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  filled: false,
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
                            Text(
                              'Status : ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            Text(
                              _buildStatusText(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                (isSubmitting ||
                                    isCheckedOut ||
                                    todayStatus == 'izin' ||
                                    !_isInRange)
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (!_isInRange ||
                                      todayStatus == 'izin' ||
                                      isCheckedOut)
                                  ? Colors.grey
                                  : isCheckedIn
                                  ? Colors.orange
                                  : const Color(0xFF5B7BFF),
                              disabledBackgroundColor: Colors.grey.shade400,
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
                                    !_isInRange
                                        ? 'Di Luar Jangkauan'
                                        : todayStatus == 'izin'
                                        ? 'Sedang Izin'
                                        : isCheckedOut
                                        ? 'Sudah Check Out'
                                        : isCheckedIn
                                        ? 'Check Out'
                                        : 'Check In',
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

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
    required bool isTop,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: isTop
            ? const BorderRadius.vertical(top: Radius.circular(10))
            : const BorderRadius.vertical(bottom: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: isTop
              ? const BorderRadius.vertical(top: Radius.circular(10))
              : const BorderRadius.vertical(bottom: Radius.circular(10)),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.access_time_outlined, 'label': 'History'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];

    final int selectedIndex = 1; // 🔥 Map aktif (CheckInPage)

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFD4E600),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = selectedIndex == i;

              return GestureDetector(
                onTap: () {
                  if (i == 0) {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                  if (i == 2) {
                    Navigator.pushNamed(context, '/history');
                  }
                  if (i == 3) {
                    Navigator.pushNamed(context, '/profile');
                  }
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

                    // 🔥 GARIS BAWAH AKTIF (INI YANG KURANG TADI)
                    if (selected)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7BFF),
                          borderRadius: BorderRadius.circular(2),
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
