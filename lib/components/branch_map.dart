// lib/components/branch_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libyan_banking_hub/models/models.dart';

class BranchMap extends StatefulWidget {
  final List<Branch> branches;

  const BranchMap({super.key, required this.branches});

  @override
  State<BranchMap> createState() => _BranchMapState();
}

class _BranchMapState extends State<BranchMap> with TickerProviderStateMixin {
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(32.8872, 13.1913);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _animatedMapMove(_userLocation!, 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultLocation,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: isDarkMode
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.libyan_banking_hub',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: [
                ...widget.branches.map((branch) {
                  Color statusColor;
                  switch (branch.status) {
                    case LiquidityStatus.available:
                      statusColor = Colors.green;
                      break;
                    case LiquidityStatus.crowded:
                      statusColor = Colors.orange;
                      break;
                    case LiquidityStatus.empty:
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.grey;
                  }

                  return Marker(
                    point: LatLng(branch.lat, branch.lng),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        _animatedMapMove(LatLng(branch.lat, branch.lng), 15.0);
                        _showBranchInfo(context, branch);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: statusColor, width: 2),
                            ),
                            child: Icon(
                              branch.isAtm ? Icons.atm : Icons.account_balance,
                              size: 20,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(100),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "reset_view",
                onPressed: () => _animatedMapMove(_defaultLocation, 13.0),
                mini: true,
                backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: const Icon(Icons.home, color: Colors.green),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: "my_location",
                onPressed: _determinePosition,
                mini: true,
                backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBranchInfo(BuildContext context, Branch branch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(branch.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (branch.isAtm)
                  Chip(
                    label: const Text("ATM", style: TextStyle(fontSize: 10)), 
                    backgroundColor: Colors.blue.withAlpha(50),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(branch.address, style: const TextStyle(color: Colors.grey))),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("حالة السيولة", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(branch.status == LiquidityStatus.available ? "متوفرة" : "مزدحمة", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: branch.status == LiquidityStatus.available ? Colors.green : Colors.orange)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.check),
                  label: const Text("تم"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
