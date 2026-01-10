import 'package:libyan_banking_hub/models/models.dart';

final List<Bank> kDefaultBanks = [
  Bank(id: '1', name: 'مصرف الجمهورية', city: 'Tripoli', logoUrl: 'https://picsum.photos/seed/gumhouria/200'),
  Bank(id: '2', name: 'مصرف الوحدة', city: 'Benghazi', logoUrl: 'https://picsum.photos/seed/wahda/200'),
  Bank(id: '3', name: 'مصرف الصحارى', city: 'Tripoli', logoUrl: 'https://picsum.photos/seed/sahara/200'),
  // ... أضف البقية
];

final List<Branch> kDefaultBranches = [
  Branch(
      id: 'b1', bankId: '1', name: 'فرع الميدان', address: 'ميدان الشهداء، طرابلس',
      lat: 32.8872, lng: 13.1913, isAtm: false, status: LiquidityStatus.available,
      lastUpdate: DateTime.now(), crowdLevel: 30
  ),
  Branch(
      id: 'b2', bankId: '1', name: 'صراف آلي - شارع عمر المختار', address: 'شارع عمر المختار',
      lat: 32.8850, lng: 13.1850, isAtm: true, status: LiquidityStatus.crowded,
      lastUpdate: DateTime.now().subtract(Duration(minutes: 30)), crowdLevel: 85
  ),
  // ... أضف البقية من constants.ts
];