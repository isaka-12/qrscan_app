import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../library/presentation/pages/library_page.dart';
import '../../../qr_maker/presentation/pages/create_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/qrscan_provider.dart';
import 'qrscan_history_page.dart';
import 'scan_page.dart';

/// App shell: Scans · Photos · Create. The Scans tab is the home screen —
/// the list of scanned codes with a Scan button that opens the camera.
/// Settings is the gear in the app bar.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  /// The Scan button shows its label until the list scrolls down, then
  /// shrinks to an icon (and grows back when scrolling up), like Gmail.
  bool _fabExtended = true;

  bool _onScroll(UserScrollNotification n) {
    final extended = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _fabExtended,
    };
    if (extended != _fabExtended) setState(() => _fabExtended = extended);
    return false;
  }

  static const _titles = ['Scans', 'Photos', 'Create'];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _openScanner() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ScannerPage()));

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const SettingsPage(),
      ),
    ),
  );

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all scans?'),
        content: const Text(
          'All scans will be removed. This can\'t be undone.',
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
              ).showSnackBar(const SnackBar(content: Text('Scans cleared')));
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

  /// Keeps content readable on tablets and in landscape.
  Widget _readable(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasScans = context.select<QrScanProvider, bool>(
      (p) => p.scans.isNotEmpty,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_titles[_selectedIndex]),
        elevation: 0,
        actions: [
          if (_selectedIndex == 0 && hasScans)
            IconButton(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all scans',
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: _readable(const QrScanHistoryPage()),
          ),
          _readable(const LibraryPage()),
          _readable(const CreatePage()),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openScanner,
              isExtended: _fabExtended,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan'),
              tooltip: 'Scan a new code',
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_2),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Scans',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Photos',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Create',
          ),
        ],
      ),
    );
  }
}
