// lib/components/branch_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libyan_banking_hub/models/models.dart';
import 'package:libyan_banking_hub/components/branch_widgets.dart';

class BranchMap extends StatefulWidget {
  final List<Branch> branches;
  final Function(Branch)? onViewDetails;

  const BranchMap({super.key, required this.branches, this.onViewDetails});

  @override
  State<BranchMap> createState() => _BranchMapState();
}

class _BranchMapState extends State<BranchMap> with TickerProviderStateMixin {
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(32.8872, 13.1913);
  Branch? _selectedBranch;

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
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
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
            onTap: (_, __) => setState(() => _selectedBranch = null),
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

                  final isSelected = _selectedBranch?.id == branch.id;

                  return Marker(
                    point: LatLng(branch.lat, branch.lng),
                    width: isSelected ? 70 : 50,
                    height: isSelected ? 70 : 50,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedBranch = branch);
                        _animatedMapMove(LatLng(branch.lat, branch.lng), 15.0);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isSelected ? 70 : 50,
                            height: isSelected ? 70 : 50,
                            decoration: BoxDecoration(
                              color: (isSelected ? Colors.blue : statusColor).withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Colors.blue : statusColor, width: 2),
                            ),
                            child: Icon(
                              branch.isAtm ? Icons.atm : Icons.account_balance,
                              size: 20,
                              color: isSelected ? Colors.blue : statusColor,
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
        
        // Persistent Bottom Sheet for Selected Branch
        if (_selectedBranch != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 1.0, end: 0.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 200),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(_selectedBranch!.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedBranch = null),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_selectedBranch!.address, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showReportDialog(context, _selectedBranch!, (id, status) {
                                setState(() => _selectedBranch = null);
                              });
                            },
                            icon: const Icon(Icons.report_problem_outlined),
                            label: const Text("إبلاغ"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.onViewDetails != null) {
                                widget.onViewDetails!(_selectedBranch!);
                              }
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text("تفاصيل"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, 
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),

        // Map Control Buttons
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: _selectedBranch != null ? 200 : 20,
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
}
