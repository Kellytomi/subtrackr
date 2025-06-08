import 'package:uuid/uuid.dart';

/// Represents a price change for a subscription with an effective date
class PriceChange {
  final String id;
  final String subscriptionId;
  final double oldPrice;
  final double newPrice;
  final DateTime effectiveDate;
  final String? reason; // Optional reason for the price change
  final DateTime createdAt;

  PriceChange({
    String? id,
    required this.subscriptionId,
    required this.oldPrice,
    required this.newPrice,
    required this.effectiveDate,
    this.reason,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this price change with some fields updated
  PriceChange copyWith({
    String? subscriptionId,
    double? oldPrice,
    double? newPrice,
    DateTime? effectiveDate,
    String? reason,
    DateTime? createdAt,
  }) {
    return PriceChange(
      id: id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      oldPrice: oldPrice ?? this.oldPrice,
      newPrice: newPrice ?? this.newPrice,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subscriptionId': subscriptionId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'effectiveDate': effectiveDate.millisecondsSinceEpoch,
      'reason': reason,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create from map
  factory PriceChange.fromMap(Map<String, dynamic> map) {
    return PriceChange(
      id: map['id'] as String,
      subscriptionId: map['subscriptionId'] as String,
      oldPrice: (map['oldPrice'] as num).toDouble(),
      newPrice: (map['newPrice'] as num).toDouble(),
      effectiveDate: DateTime.fromMillisecondsSinceEpoch(map['effectiveDate'] as int),
      reason: map['reason'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  /// Calculate the price difference
  double get priceDifference => newPrice - oldPrice;

  /// Check if this is a price increase
  bool get isPriceIncrease => newPrice > oldPrice;

  /// Check if this is a price decrease
  bool get isPriceDecrease => newPrice < oldPrice;

  /// Get percentage change
  double get percentageChange {
    if (oldPrice == 0) return 0;
    return ((newPrice - oldPrice) / oldPrice) * 100;
  }

  @override
  String toString() {
    return 'PriceChange{id: $id, subscriptionId: $subscriptionId, oldPrice: $oldPrice, newPrice: $newPrice, effectiveDate: $effectiveDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceChange && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 