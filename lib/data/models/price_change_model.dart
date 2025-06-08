import 'package:hive/hive.dart';
import 'package:subtrackr/domain/entities/price_change.dart';

part 'price_change_model.g.dart';

@HiveType(typeId: 1) // Using typeId 1 since 0 is used for SubscriptionModel
class PriceChangeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subscriptionId;

  @HiveField(2)
  final double oldPrice;

  @HiveField(3)
  final double newPrice;

  @HiveField(4)
  final DateTime effectiveDate;

  @HiveField(5)
  final String? reason;

  @HiveField(6)
  final DateTime createdAt;

  PriceChangeModel({
    required this.id,
    required this.subscriptionId,
    required this.oldPrice,
    required this.newPrice,
    required this.effectiveDate,
    this.reason,
    required this.createdAt,
  });

  // Convert from domain entity to Hive model
  factory PriceChangeModel.fromEntity(PriceChange priceChange) {
    return PriceChangeModel(
      id: priceChange.id,
      subscriptionId: priceChange.subscriptionId,
      oldPrice: priceChange.oldPrice,
      newPrice: priceChange.newPrice,
      effectiveDate: priceChange.effectiveDate,
      reason: priceChange.reason,
      createdAt: priceChange.createdAt,
    );
  }

  // Convert from Hive model to domain entity
  PriceChange toEntity() {
    return PriceChange(
      id: id,
      subscriptionId: subscriptionId,
      oldPrice: oldPrice,
      newPrice: newPrice,
      effectiveDate: effectiveDate,
      reason: reason,
      createdAt: createdAt,
    );
  }
} 