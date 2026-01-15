// lib/components/branch_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:libyan_banking_hub/models/models.dart';
import 'package:libyan_banking_hub/components/branch_widgets.dart';
import 'package:libyan_banking_hub/services/location_service.dart';

// --- Mini Branch Map Widget ---

class MiniBranchMap extends StatelessWidget {
  final Branch branch;

  const MiniBranchMap({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 128, // h-32
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF1F2937) : Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(branch.lat, branch.lng),
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable all interactions
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.libyan_banking_hub',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(branch.lat, branch.lng),
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getVibrantStatusColor(branch.status),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.3).round()),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _getVibrantStatusColor(LiquidityStatus status) {
  switch (status) {
    case LiquidityStatus.available: return Colors.green;
    case LiquidityStatus.crowded: return Colors.orange;
    case LiquidityStatus.empty: return Colors.red;
    default: return Colors.grey;
  }
}

// --- Main Branch Map Widget ---

class BranchMap extends StatefulWidget {
  final List<Branch> branches;
  final Function(Branch) onViewDetails;
  final Function(String, LiquidityStatus)? onReport;

  const BranchMap({
    super.key,
    required this.branches,
    required this.onViewDetails,
    this.onReport,
  });

  @override
  State<BranchMap> createState() => _BranchMapState();
}

class _BranchMapState extends State<BranchMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(32.8872, 13.1913); // Tripoli
  static const double _defaultZoom = 12.0;

  Branch? _selectedBranch;
  bool _isLocating = false;
  LatLng? _userLocation;

  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _fitBounds() {
    if (widget.branches.isEmpty || _selectedBranch != null) return;
    final bounds = LatLngBounds.fromPoints(
      widget.branches.map((b) => LatLng(b.lat, b.lng)).toList(),
    );
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _animationController?.dispose();

    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    _animationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: _animationController!, curve: Curves.fastOutSlowIn);

    _animationController!.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation));
    });

    _animationController!.forward();
  }

  Future<void> _handleLocateMe() async {
    setState(() => _isLocating = true);
    final location = await LocationService.getCurrentLocation(context);
    if (location != null && mounted) {
      setState(() {
        _userLocation = location;
        _isLocating = false;
      });
      _animatedMapMove(_userLocation!, 14.0);
    } else {
      setState(() => _isLocating = false);
    }
  }

  void _handleResetView() {
    _animatedMapMove(_defaultCenter, _defaultZoom);
    setState(() => _selectedBranch = null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: _defaultZoom,
            onTap: (_, __) => setState(() => _selectedBranch = null),
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.libyan_banking_hub',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: [
                ...widget.branches.map((branch) {
                  final isSelected = _selectedBranch?.id == branch.id;
                  return Marker(
                    point: LatLng(branch.lat, branch.lng),
                    width: isSelected ? 50 : 30,
                    height: isSelected ? 50 : 30,
                    child: GestureDetector(
                      onTap: () {
                         _animatedMapMove(LatLng(branch.lat, branch.lng), 15.0);
                         setState(() => _selectedBranch = branch);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : _getVibrantStatusColor(branch.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isSelected ? 4 : 3),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.3).round()), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: isSelected ? Icon(branch.isAtm ? Icons.atm : Icons.account_balance, color: Colors.white, size: 20) : null,
                      ),
                    ),
                  );
                }),
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 24, height: 24,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withAlpha((255 * 0.3).round()))),
                        Container(width: 16, height: 16, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: _selectedBranch != null ? 260 : 20,
          right: 20,
          child: Column(
            children: [
              _buildMapBtn(icon: Icons.refresh, onTap: _handleResetView, tooltip: "إعادة تعيين", isDark: isDark),
              const SizedBox(height: 8),
              _buildMapBtn(icon: Icons.my_location, onTap: _handleLocateMe, tooltip: "موقعي", isLoading: _isLocating, isDark: isDark),
            ],
          ),
        ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: _selectedBranch != null ? -150 : 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF1F2937) : Colors.white).withAlpha((255 * 0.9).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("مفتاح الحالة", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                _buildLegendItem(LiquidityStatus.available),
                _buildLegendItem(LiquidityStatus.crowded),
                _buildLegendItem(LiquidityStatus.empty),
              ],
            ),
          ),
        ),

        if (_selectedBranch != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 1.0, end: 0.0),
              builder: (context, value, child) => Transform.translate(offset: Offset(0, value * 200), child: child),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.1).round()), blurRadius: 15, offset: const Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() => _selectedBranch = null), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(_selectedBranch!.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (_selectedBranch!.isAtm)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.withAlpha((255 * 0.1).round()), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.withAlpha((255 * 0.3).round()))),
                                      child: const Text("ATM", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              Row(children: [const Icon(Icons.location_on, size: 12, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(_selectedBranch!.address, style: const TextStyle(fontSize: 12, color: Colors.grey)))]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDark ? Colors.black.withAlpha((255 * 0.2).round()) : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("آخر تحديث", style: TextStyle(fontSize: 10, color: Colors.grey)), Text(DateFormat('hh:mm a').format(_selectedBranch!.lastUpdate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                          StatusBadge(status: _selectedBranch!.status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showReportDialog(context, _selectedBranch!, (id, status) {
                                if (widget.onReport != null) {
                                  widget.onReport!(id, status);
                                }
                                setState(() => _selectedBranch = null);
                              });
                            },
                            icon: const Icon(Icons.add_chart_outlined, size: 16),
                            label: const Text("إبلاغ"),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () => widget.onViewDetails(_selectedBranch!), icon: const Icon(Icons.info_outline, size: 16), label: const Text("عرض التفاصيل"), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapBtn({required IconData icon, required VoidCallback onTap, required String tooltip, bool isLoading = false, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1F2937) : Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)], border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[100]!)),
      child: IconButton(icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 20), onPressed: isLoading ? null : onTap, tooltip: tooltip, color: isDark ? Colors.white : Colors.grey[700]),
    );
  }

  Widget _buildLegendItem(LiquidityStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: _getVibrantStatusColor(status), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))),
          const SizedBox(width: 8),
          Text(status.label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
