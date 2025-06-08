import 'package:hive_flutter/hive_flutter.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/data/models/price_change_model.dart';
import 'package:subtrackr/domain/entities/price_change.dart';

class PriceChangeRepository {
  static final PriceChangeRepository _instance = PriceChangeRepository._internal();
  
  factory PriceChangeRepository() {
    return _instance;
  }
  
  PriceChangeRepository._internal();
  
  late Box<PriceChangeModel> _priceChangesBox;
  
  // Initialize the repository
  Future<void> init() async {
    // Register the adapter
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter<PriceChangeModel>(PriceChangeModelAdapter());
    }
    
    // Open the box
    _priceChangesBox = await Hive.openBox<PriceChangeModel>('price_changes');
  }
  
  // Get all price changes
  List<PriceChange> getAllPriceChanges() {
    return _priceChangesBox.values.map((model) => model.toEntity()).toList();
  }
  
  // Get price changes for a specific subscription
  List<PriceChange> getPriceChangesForSubscription(String subscriptionId) {
    return _priceChangesBox.values
        .where((model) => model.subscriptionId == subscriptionId)
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
  }
  
  // Get upcoming price changes
  List<PriceChange> getUpcomingPriceChanges() {
    final now = DateTime.now();
    return _priceChangesBox.values
        .where((model) => model.effectiveDate.isAfter(now))
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
  }
  
  // Get price change by ID
  PriceChange? getPriceChangeById(String id) {
    final models = _priceChangesBox.values.where((model) => model.id == id);
    if (models.isEmpty) {
      return null;
    }
    return models.first.toEntity();
  }
  
  // Add a new price change
  Future<void> addPriceChange(PriceChange priceChange) async {
    final model = PriceChangeModel.fromEntity(priceChange);
    await _priceChangesBox.put(priceChange.id, model);
  }
  
  // Update an existing price change
  Future<void> updatePriceChange(PriceChange priceChange) async {
    final model = PriceChangeModel.fromEntity(priceChange);
    await _priceChangesBox.put(priceChange.id, model);
  }
  
  // Delete a price change
  Future<void> deletePriceChange(String id) async {
    await _priceChangesBox.delete(id);
  }
  
  // Delete all price changes for a subscription
  Future<void> deletePriceChangesForSubscription(String subscriptionId) async {
    final keysToDelete = <dynamic>[];
    for (final entry in _priceChangesBox.toMap().entries) {
      if (entry.value.subscriptionId == subscriptionId) {
        keysToDelete.add(entry.key);
      }
    }
    
    for (final key in keysToDelete) {
      await _priceChangesBox.delete(key);
    }
  }
  
  // Get recent price changes (last 30 days)
  List<PriceChange> getRecentPriceChanges() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _priceChangesBox.values
        .where((model) => model.createdAt.isAfter(thirtyDaysAgo))
        .map((model) => model.toEntity())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
} 