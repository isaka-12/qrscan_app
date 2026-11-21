import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/location_helper.dart';
import '../../../qr_maker/presentation/pages/create_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../domain/entities/scan.dart';
import '../providers/qrscan_provider.dart';
import 'qrscan_page.dart';
import 'qrscan_history_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  MobileScannerController? _scanController;

  late final List<Widget> _pages;
  static const _titles = ['Locus', 'Scan History', 'Create QR', 'Settings'];

  @override
  void initState() {
    super.initState();
    _pages = [
      QrScanPage(
        onViewAllTapped: () => _onItemTapped(1),
        onScanTapped: _startScanning,
        onCreateTapped: () => _onItemTapped(2),
      ),
      const QrScanHistoryPage(),
      const CreatePage(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  void _startScanning() async {
    _scanController = MobileScannerController();
    await _showScannerBottomSheet();
  }

  Future<void> _showScannerBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetCtx) {
        final height = MediaQuery.of(sheetCtx).size.height * 2 / 3;
        final colorScheme = Theme.of(sheetCtx).colorScheme;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Scan QR Code',
                      style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _stopScanning,
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              // Camera view
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: _scanController!,
                      onDetect: _onQrDetected,
                    ),
                  ),
                ),
              ),
              // Hint
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                child: Text(
                  'Position the QR code within the frame',
                  style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onQrDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || !mounted) return;

    _stopScanning();

    final provider = context.read<QrScanProvider>();
    provider.setProcessingScan(true);

    try {
      final (lat, lng, address) = await LocationHelper.getCurrentLocation();

      final scan = Scan(
        qrData: barcodes.first.displayValue ?? 'Unknown',
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
        address: address,
      );

      await provider.addScan(scan);
      provider.setProcessingScan(false);

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                const Text('QR code scanned successfully!'),
              ],
            ),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      provider.setProcessingScan(false);

      if (mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: colorScheme.onError),
                const SizedBox(width: 8),
                Expanded(child: Text('Error processing scan: $e')),
              ],
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _stopScanning() {
    _scanController?.dispose();
    _scanController = null;
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _scanController?.dispose();
    super.dispose();
  }

  // ── History actions ───────────────────────────────────────────────────────

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all scan history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<QrScanProvider>().clearScans();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('History cleared')));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrScanProvider = Provider.of<QrScanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_selectedIndex == 1 && qrScanProvider.scans.isNotEmpty)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
            ),
        ],
      ),
      // Keeps content readable on tablets and in landscape.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: IndexedStack(index: _selectedIndex, children: _pages),
        ),
      ),
      floatingActionButton: Theme(
        data: Theme.of(context).copyWith(
          floatingActionButtonTheme: Theme.of(context).floatingActionButtonTheme
              .copyWith(
                sizeConstraints: const BoxConstraints.tightFor(
                  width: 72,
                  height: 72,
                ),
              ),
        ),
        child: FloatingActionButton(
          onPressed: _startScanning,
          elevation: 4,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner, size: 45),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12,
        height: 68,
        padding: EdgeInsets.zero,
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        child: Row(
          children: [
            // Two tabs each side of the Scan button.
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      index: 0,
                      selectedIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      label: 'History',
                      index: 1,
                      selectedIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 80),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.add_box_outlined,
                      activeIcon: Icons.add_box,
                      label: 'Create',
                      index: 2,
                      selectedIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                      index: 3,
                      selectedIndex: _selectedIndex,
                      onTap: _onItemTapped,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              // Large system font sizes must not break the fixed-height bar.
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.2),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
