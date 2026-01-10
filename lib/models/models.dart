// lib/models/models.dart

// تحويل الـ Enum
enum LiquidityStatus {
  available,
  crowded,
  empty,
  unknown
}

// تحويل واجهة الفرع Branch
class Branch {
  final String id;
  final String bankId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final bool isAtm;
  final LiquidityStatus status;
  final DateTime lastUpdate;
  final int crowdLevel;

  Branch({
    required this.id,
    required this.bankId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.isAtm,
    required this.status,
    required this.lastUpdate,
    required this.crowdLevel,
  });

  Branch copyWith({
    String? id,
    String? bankId,
    String? name,
    String? address,
    double? lat,
    double? lng,
    bool? isAtm,
    LiquidityStatus? status,
    DateTime? lastUpdate,
    int? crowdLevel,
  }) {
    return Branch(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isAtm: isAtm ?? this.isAtm,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      crowdLevel: crowdLevel ?? this.crowdLevel,
    );
  }
}

// تحويل واجهة المصرف Bank
class Bank {
  final String id;
  final String name;
  final String logoUrl;
  final String city;

  Bank({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.city,
  });
}
