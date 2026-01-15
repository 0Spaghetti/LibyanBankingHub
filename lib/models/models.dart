import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum AppView { splash, onboarding, auth, home, map, add, emergency, profile }

enum LiquidityStatus {
  available,
  crowded,
  empty,
  unknown
}

extension LiquidityStatusX on LiquidityStatus {
  String get label {
    switch (this) {
      case LiquidityStatus.available: return "سيولة متوفرة";
      case LiquidityStatus.crowded: return "مزدحم";
      case LiquidityStatus.empty: return "فارغ";
      case LiquidityStatus.unknown: return "غير معروف";
    }
  }

  Color color(bool isDark) {
    switch (this) {
      case LiquidityStatus.available:
        return isDark ? AppColors.green300 : AppColors.green800;
      case LiquidityStatus.crowded:
        return isDark ? AppColors.yellow300 : AppColors.yellow800;
      case LiquidityStatus.empty:
        return isDark ? AppColors.red300 : AppColors.red800;
      case LiquidityStatus.unknown:
        return isDark ? AppColors.gray400 : AppColors.gray500;
    }
  }

  Color backgroundColor(bool isDark) {
    switch (this) {
      case LiquidityStatus.available:
        return isDark ? AppColors.green900.withAlpha(128) : AppColors.green100;
      case LiquidityStatus.crowded:
        return isDark ? AppColors.yellow900.withAlpha(128) : AppColors.yellow100;
      case LiquidityStatus.empty:
        return isDark ? AppColors.red900.withAlpha(128) : AppColors.red100;
      case LiquidityStatus.unknown:
        return isDark ? AppColors.gray700 : AppColors.gray100;
    }
  }
}

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankId': bankId,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'isAtm': isAtm,
      'status': status.index,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
      'crowdLevel': crowdLevel,
    };
  }

  factory Branch.fromMap(Map<String, dynamic> map) {
    return Branch(
      id: map['id'],
      bankId: map['bankId'],
      name: map['name'],
      address: map['address'],
      lat: map['lat'],
      lng: map['lng'],
      isAtm: map['isAtm'],
      status: LiquidityStatus.values[map['status']],
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(map['lastUpdate']),
      crowdLevel: map['crowdLevel'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Branch.fromJson(String source) => Branch.fromMap(json.decode(source));
}

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'city': city,
    };
  }

  factory Bank.fromMap(Map<String, dynamic> map) {
    return Bank(
      id: map['id'],
      name: map['name'],
      logoUrl: map['logoUrl'],
      city: map['city'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Bank.fromJson(String source) => Bank.fromMap(json.decode(source));
}
