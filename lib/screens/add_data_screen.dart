import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

class AddDataScreen extends StatefulWidget {
  final List<Bank> banks;
  final Function(Bank) onAddBank;
  final Function(Branch) onAddBranch;
  final VoidCallback onCancel;

  const AddDataScreen({
    super.key,
    required this.banks,
    required this.onAddBank,
    required this.onAddBranch,
    required this.onCancel,
  });

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> with SingleTickerProviderStateMixin {
  // Tab State
  String _activeTab = 'BANK'; // 'BANK' or 'BRANCH'

  // Bank Form Controllers
  final _bankNameController = TextEditingController();
  final _bankCityController = TextEditingController(text: "طرابلس");
  final _bankFormKey = GlobalKey<FormState>();

  // Branch Form Controllers
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _branchFormKey = GlobalKey<FormState>();
  
  String? _selectedBankId;
  bool _isAtm = false;

  // Location State
  LatLng _selectedLocation = const LatLng(32.8872, 13.1913);
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.banks.isNotEmpty) {
      _selectedBankId = widget.banks[0].id;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankCityController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
    }
  }

  void _handleBankSubmit() {
    if (_bankFormKey.currentState!.validate()) {
      final name = _bankNameController.text;
      
      final newBank = Bank(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        city: _bankCityController.text,
        logoUrl: "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff",
      );

      widget.onAddBank(newBank);

      // UX Improvement: Auto-select this bank for the next step (Branch)
      setState(() {
        _selectedBankId = newBank.id;
        _activeTab = 'BRANCH';
      });

      _bankNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المصرف بنجاح. يمكنك الآن إضافة فرع له.')));
    }
  }

  void _handleBranchSubmit() {
    if (_branchFormKey.currentState!.validate() && _selectedBankId != null) {
      final newBranch = Branch(
        id: "new-${DateTime.now().millisecondsSinceEpoch}",
        bankId: _selectedBankId!,
        name: _branchNameController.text,
        address: _branchAddressController.text,
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
        isAtm: _isAtm,
        status: LiquidityStatus.unknown,
        lastUpdate: DateTime.now(),
        crowdLevel: 0,
      );

      widget.onAddBranch(newBranch);

      // UX Improvement: Close screen after successful branch addition
      widget.onCancel(); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الفرع بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة بيانات جديدة"),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: widget.onCancel),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Tabs ---
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    children: [
                      _buildTab('BANK', 'إضافة مصرف', primaryColor, isDark),
                      _buildTab('BRANCH', 'إضافة فرع', primaryColor, isDark),
                    ],
                  ),
                ),

                // --- Form Content ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _activeTab == 'BANK' 
                    ? _buildBankForm(isDark, primaryColor) 
                    : _buildBranchForm(isDark, primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String id, String label, Color primaryColor, bool isDark) {
    final isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _activeTab = id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive 
              ? (isDark ? primaryColor.withAlpha(20) : primaryColor.withAlpha(10))
              : null,
            border: isActive 
              ? Border(bottom: BorderSide(color: primaryColor, width: 2)) 
              : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isActive 
                ? primaryColor 
                : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankForm(bool isDark, Color primaryColor) {
    return Form(
      key: _bankFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel("اسم المصرف", isDark),
          _buildInput(_bankNameController, "مثال: مصرف الجمهورية", isDark),
          const SizedBox(height: 16),
          
          _buildLabel("المدينة الرئيسية", isDark),
          _buildInput(_bankCityController, "مثال: طرابلس", isDark),
          const SizedBox(height: 24),
          
          _buildSubmitButton("حفظ المصرف", _handleBankSubmit, primaryColor),
        ],
      ),
    );
  }

  Widget _buildBranchForm(bool isDark, Color primaryColor) {
    return Form(
      key: _branchFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel("اختر المصرف", isDark),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedBankId,
                decoration: const InputDecoration(border: InputBorder.none),
                dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                items: widget.banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank.id,
                    child: Text(bank.name, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBankId = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel("اسم الفرع", isDark),
          _buildInput(_branchNameController, "مثال: فرع ذات العماد", isDark),
          const SizedBox(height: 16),

          _buildLabel("العنوان", isDark),
          _buildInput(_branchAddressController, "مثال: طريق الشط", isDark),
          const SizedBox(height: 24),

          _buildLabel("موقع الفرع على الخريطة", isDark),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 14.0,
                      onTap: (tapPosition, point) => setState(() => _selectedLocation = point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.libyan_banking_hub',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: FloatingActionButton.small(
                      heroTag: "add_branch_loc",
                      onPressed: _getCurrentLocation,
                      backgroundColor: isDark ? const Color(0xFF374151) : Colors.white,
                      child: _isGettingLocation 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: _isAtm,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _isAtm = val ?? false),
              ),
              const Text("صراف آلي (ATM)", style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),

          _buildSubmitButton("حفظ الفرع", _handleBranchSubmit, primaryColor),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, bool isDark) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.start,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed, Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
