import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import '../widgets/scan_details_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/scan_card_widget.dart';

class QrScanHistoryPage extends StatefulWidget {
  const QrScanHistoryPage({super.key});

  @override
  State<QrScanHistoryPage> createState() => _QrScanHistoryPageState();
}

class _QrScanHistoryPageState extends State<QrScanHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Scan> _filteredScans = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<QrScanProvider>();
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredScans = List.from(provider.scans);
      } else {
        _filteredScans = provider.scans
            .where(
              (scan) =>
                  scan.qrData.toLowerCase().contains(query) ||
                  scan.address.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  void _showScanDetails(Scan scan) {
    ScanDetailsDialog.show(context: context, scan: scan);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QrScanProvider>();

    // Update filtered scans when provider data changes
    if (_searchController.text.isEmpty) {
      _filteredScans = List.from(provider.scans);
    } else {
      // Reapply search filter with updated data
      _onSearchChanged();
    }

    return Scaffold(
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.scans.isEmpty
          ? const EmptyStateWidget(type: EmptyStateType.noHistory)
          : Column(
              children: [
                // Search bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search scans...',
                      hintStyle: TextStyle(color: AppTheme.appGrey),
                      prefixIcon: Icon(Icons.search, color: AppTheme.appGrey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                              },
                              icon: Icon(Icons.clear, color: AppTheme.appGrey),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                // Results count
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredScans.length} scan${_filteredScans.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.accentLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        Text(
                          'of ${provider.scans.length} total',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.appGrey),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Scan history list
                Expanded(
                  child: _filteredScans.isEmpty
                      ? const EmptyStateWidget(
                          type: EmptyStateType.noSearchResults,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredScans.length,
                          itemBuilder: (context, index) {
                            final scan = _filteredScans[index];

                            return ScanCardWidget(
                              scan: scan,
                              onTap: () => _showScanDetails(scan),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
