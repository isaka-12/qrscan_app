import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../qrscan/presentation/providers/qrscan_provider.dart';

/// Settings: scanning & privacy, appearance, data, about.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _clearScans(BuildContext context, int count) async {
    final provider = context.read<QrScanProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all scans?'),
        content: Text(
          '$count scan${count == 1 ? '' : 's'} will be removed. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await provider.clearScans();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scans cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = context.watch<ThemeProvider>();
    final scanCount = context.select<QrScanProvider, int>(
      (p) => p.scans.length,
    );
    final colorScheme = Theme.of(context).colorScheme;

    Widget divider() =>
        Divider(height: 1, indent: 72, color: colorScheme.outlineVariant);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _Section(
          title: 'Scanning & privacy',
          children: [
            SwitchListTile(
              secondary: const _TileIcon(Icons.history),
              title: const Text('Save scans'),
              subtitle: const Text('Keep scanned codes in your Scans list'),
              value: settings.saveScans,
              onChanged: (v) => settings.saveScans = v,
            ),
            divider(),
            SwitchListTile(
              secondary: _TileIcon(
                settings.saveLocation
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
              ),
              title: const Text('Save location'),
              subtitle: Text(
                settings.saveScans
                    ? 'Record where each code was scanned'
                    : 'Turn on "Save scans" first',
              ),
              value: settings.saveScans && settings.saveLocation,
              onChanged: settings.saveScans
                  ? (v) => settings.saveLocation = v
                  : null,
            ),
            divider(),
            SwitchListTile(
              secondary: const _TileIcon(Icons.vibration),
              title: const Text('Vibrate on scan'),
              value: settings.vibrate,
              onChanged: (v) => settings.vibrate = v,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Appearance',
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _TileIcon(Icons.palette_outlined),
                      const SizedBox(width: 16),
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        selectedForegroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('System'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Dark'),
                        ),
                      ],
                      selected: {theme.themeMode},
                      onSelectionChanged: (s) => theme.setThemeMode(s.first),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Data',
          children: [
            ListTile(
              leading: _TileIcon(
                Icons.delete_sweep_outlined,
                color: scanCount == 0 ? null : colorScheme.error,
              ),
              title: Text(
                'Clear all scans',
                style: TextStyle(
                  color: scanCount == 0 ? null : colorScheme.error,
                ),
              ),
              subtitle: Text(
                scanCount == 0
                    ? 'No scans saved'
                    : '$scanCount scan${scanCount == 1 ? '' : 's'} saved',
              ),
              enabled: scanCount > 0,
              onTap: () => _clearScans(context, scanCount),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'About',
          children: [
            ListTile(
              leading: const _TileIcon(Icons.info_outline),
              title: const Text('About Locus'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Locus',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.qr_code_scanner,
                  color: colorScheme.primary,
                  size: 40,
                ),
                children: const [
                  Text(
                    'Scan QR codes and keep them with time and place, '
                    'organize photos, and create codes and photo posts.',
                  ),
                ],
              ),
            ),
            divider(),
            ListTile(
              leading: const _TileIcon(Icons.description_outlined),
              title: const Text('Open-source licenses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  showLicensePage(context: context, applicationName: 'Locus'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  const _TileIcon(this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: c, size: 20),
    );
  }
}
