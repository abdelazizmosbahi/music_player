import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../data/datasources/local_media_scanner.dart';
import '../providers/media_provider.dart';

class PermissionGate extends ConsumerStatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate> {
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequest();
  }

  Future<void> _checkAndRequest() async {
    final scanner = LocalMediaScanner();

    // Check existing permission
    bool granted = await scanner.hasPermission();

    if (!granted) {
      // Don't auto-request yet — wait for user tap
      setState(() { _isLoading = false; _hasPermission = false; });
      return;
    }

    setState(() { _hasPermission = true; _isLoading = false; });
    await _scanMedia();
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    final scanner = LocalMediaScanner();
    final granted = await scanner.requestPermission();

    if (granted) {
      setState(() { _hasPermission = true; _isLoading = false; });
      await _scanMedia();
    } else {
      setState(() { _isLoading = false; });
      // Show settings redirect option
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission is required to access your music.'),
            action: SnackBarAction(
              label: 'Settings',
              textColor: AppColors.accent,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _scanMedia() async {
    if (_hasScanned) return;
    setState(() => ref.read(isScanningProvider.notifier).state = true);

    final repo = ref.read(mediaRepositoryProvider);
    await repo.refreshMediaLibrary();

    _hasScanned = true;
    setState(() {
      ref.read(isScanningProvider.notifier).state = false;
    });
    ref.invalidate(allSongsProvider);
    ref.invalidate(recentlyPlayedProvider);
    ref.invalidate(allAlbumsProvider);
    ref.invalidate(allArtistsProvider);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 16),
              Text('Scanning for music...', style: AppTextStyles.bodyMediumSecondary),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return _PermissionScreen(onGrant: _requestPermission);
    }

    return widget.child;
  }
}

class _PermissionScreen extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionScreen({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.library_music_rounded,
                  color: AppColors.accent,
                  size: 56,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
                    duration: 500.ms, curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 40),

              Text(
                'Access Your Music',
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              Text(
                'LocalWave needs access to your device\'s audio files\n'
                'to build your music library.\n\n'
                'We only read local files — nothing leaves your device.',
                style: AppTextStyles.bodyMediumSecondary,
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onGrant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Allow Access',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.background),
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              TextButton(
                onPressed: onGrant,
                child: Text(
                  'Scan for Music',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
