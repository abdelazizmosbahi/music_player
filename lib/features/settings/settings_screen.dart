import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _crossfadeDuration = AppConstants.crossfadeDuration.inSeconds.toDouble();
  bool _gaplessPlayback = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Playback Section
          _buildSectionHeader('Playback'),
          _buildSliderTile(
            title: 'Crossfade',
            subtitle: '${_crossfadeDuration.toInt()} seconds',
            value: _crossfadeDuration,
            min: 0,
            max: 12,
            divisions: 12,
            onChanged: (value) {
              setState(() => _crossfadeDuration = value);
            },
          ),
          _buildSwitchTile(
            title: 'Gapless Playback',
            subtitle: 'Seamless transitions between songs',
            value: _gaplessPlayback,
            onChanged: (value) {
              setState(() => _gaplessPlayback = value);
            },
          ),

          // Library Section
          _buildSectionHeader('Library'),
          _buildActionTile(
            title: 'Rescan Music',
            subtitle: 'Scan device for new music files',
            icon: Icons.refresh_rounded,
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanning for music...')),
              );
              final repo = ref.read(mediaRepositoryProvider);
              await repo.refreshMediaLibrary();
              ref.invalidate(allSongsProvider);
              ref.invalidate(recentlyPlayedProvider);
              ref.invalidate(allAlbumsProvider);
              ref.invalidate(allArtistsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Music library updated')),
                );
              }
            },
          ),
          _buildActionTile(
            title: 'Exclude Folders',
            subtitle: 'Choose folders to exclude from library',
            icon: Icons.folder_off_rounded,
            onTap: () {},
          ),
          _buildActionTile(
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            icon: Icons.cleaning_services_rounded,
            onTap: () {
              _showClearCacheDialog();
            },
          ),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildAccentColorPicker(),

          // About Section
          _buildSectionHeader('About'),
          _buildInfoTile(
            title: 'Version',
            value: AppConstants.appVersion,
          ),
          _buildActionTile(
            title: 'Open Source Licenses',
            subtitle: 'View licenses for packages used',
            icon: Icons.code_rounded,
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            ),
          ),
          _buildActionTile(
            title: 'Privacy Policy',
            subtitle: 'We only access local files on your device',
            icon: Icons.shield_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmallSecondary)
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: AppTextStyles.bodyLarge),
            subtitle: subtitle != null
                ? Text(subtitle, style: AppTextStyles.bodySmallSecondary)
                : null,
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmallSecondary)
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: Text(value, style: AppTextStyles.bodyMediumSecondary),
    );
  }

  Widget _buildAccentColorPicker() {
    final colors = [
      ('Green', AppColors.accent),
      ('Purple', const Color(0xFF7C3AED)),
      ('Blue', const Color(0xFF2FA8FF)),
      ('Coral', const Color(0xFFFF6B6B)),
      ('Orange', const Color(0xFFFF9800)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: colors.map((entry) {
          final (name, color) = entry;
          return GestureDetector(
            onTap: () {
              // TODO: Update accent color globally
            },
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(name, style: AppTextStyles.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear cached album art and temporary files. Your music and playlists will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
