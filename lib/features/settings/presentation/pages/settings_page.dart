import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

/// The Settings tab: appearance and app info.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _Section(
          title: 'Appearance',
          children: [
            SwitchListTile(
              secondary: _TileIcon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Dark mode'),
              subtitle: Text(
                themeProvider.isDarkMode ? 'On' : 'Off',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
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
                    'Scan QR codes and keep a history with time and place, '
                    'or create your own codes to save and share.',
                  ),
                ],
              ),
            ),
            Divider(height: 1, indent: 72, color: colorScheme.outlineVariant),
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;
  const _TileIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 20),
    );
  }
}
