import 'package:flutter/material.dart';
import 'package:qrscan_app/features/qrscan/domain/entities/scan.dart';
import 'package:qrscan_app/features/qrscan/data/models/scan_model.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/save_scan.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/get_all_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/search_scans.dart';
import 'package:qrscan_app/features/qrscan/domain/usecase/clear_all_scans.dart';

// Provider class for managing QR scan state and interactions.
class QrScanProvider extends ChangeNotifier {
  final SaveScan saveScanUseCase;
  final GetAllScans getAllScansUseCase;
  final SearchScans searchScansUseCase;
  final ClearAllScans clearAllScansUseCase;

  bool isLoading = false;
  bool isProcessingScan = false;
  String? error;

  void setProcessingScan(bool value) {
    isProcessingScan = value;
    notifyListeners();
  }

  List<Scan> scans = [];
  bool _isInitialized = false;

  QrScanProvider(
    this.saveScanUseCase,
    this.getAllScansUseCase,
    this.searchScansUseCase,
    this.clearAllScansUseCase,
  ) {
    _initializeScans();
  }

  /// Initialize scans by loading from database
  Future<void> _initializeScans() async {
    if (_isInitialized) return;

    try {
      isLoading = true;
      notifyListeners();

      scans = await getAllScansUseCase();
      _isInitialized = true;

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Failed to load scan history: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new scan and save it
  Future<void> addScan(Scan scan) async {
    try {
      // Save to database (this is fast)
      await saveScanUseCase(scan);

      // Convert Scan entity to ScanModel to match the list type from database
      final scanModel = ScanModel.fromEntity(scan);

      // Add to the beginning of the list to show most recent first
      scans.insert(0, scanModel);

      // Notify listeners immediately so UI updates
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Failed to save scan: $e';
      notifyListeners();
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  /// Refresh scans from database
  Future<void> refreshScans() async {
    try {
      isLoading = true;
      notifyListeners();

      scans = await getAllScansUseCase();

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Failed to refresh scans: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Search scans with a query
  Future<List<Scan>> searchScans(String query) async {
    try {
      return await searchScansUseCase(query);
    } catch (e) {
      error = 'Failed to search scans: $e';
      notifyListeners();
      return [];
    }
  }

  /// Clear all scans
  Future<void> clearScans() async {
    try {
      isLoading = true;
      notifyListeners();

      await clearAllScansUseCase();
      scans.clear();

      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Failed to clear scans: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Get recent scans (for display purposes)
  List<Scan> getRecentScans(int limit) {
    return scans.take(limit).toList();
  }

  /// Check if there are any scans
  bool get hasScans => scans.isNotEmpty;

  /// Get total count of scans
  int get scanCount => scans.length;
}
