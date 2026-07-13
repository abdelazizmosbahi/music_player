import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants.dart';
import '../../providers/media_provider.dart';

class SleepTimerScreen extends ConsumerStatefulWidget {
  const SleepTimerScreen({super.key});

  @override
  ConsumerState<SleepTimerScreen> createState() => _SleepTimerScreenState();
}

class _SleepTimerScreenState extends ConsumerState<SleepTimerScreen> {
  int? _selectedMinutes;

  @override
  Widget build(BuildContext context) {
    final timerService = ref.read(sleepTimerServiceProvider);
    final isActive = timerService.isActive;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sleep Timer'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isActive) _buildActiveTimer(timerService),
            if (!isActive) ...[
              Text(
                'Music will stop playing after the selected duration.',
                style: AppTextStyles.bodyMediumSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildTimerGrid(),
              const SizedBox(height: 24),
              _buildCustomTimeButton(),
            ],
            const Spacer(),
            _buildActionButton(isActive, timerService),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimer(timerService) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.nightlight_round, size: 64, color: AppColors.accent.withOpacity(0.8)),
        const SizedBox(height: 24),
        Text('Sleep timer active', style: AppTextStyles.headingMedium),
        const SizedBox(height: 8),
        Text('Music will stop in', style: AppTextStyles.bodyMediumSecondary),
        const SizedBox(height: 8),
        StreamBuilder<int>(
          stream: timerService.remainingSecondsStream,
          initialData: timerService.remainingSeconds,
          builder: (context, snapshot) {
            final remaining = snapshot.data ?? 0;
            final mins = remaining ~/ 60;
            final secs = remaining % 60;
            return Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: AppTextStyles.displayLarge.copyWith(color: AppColors.accent, fontSize: 48),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.9, 0.9), end: const Offset(1, 1),
          duration: 400.ms, curve: Curves.easeOutCubic,
        );
  }

  Widget _buildTimerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      ),
      itemCount: AppConstants.sleepTimerOptions.length,
      itemBuilder: (context, index) {
        final minutes = AppConstants.sleepTimerOptions[index];
        final isSelected = _selectedMinutes == minutes;
        return GestureDetector(
          onTap: () => setState(() => _selectedMinutes = minutes),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _formatMinutes(minutes),
                style: AppTextStyles.headingMedium.copyWith(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildCustomTimeButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 0, minute: 30),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.card),
            ),
            child: child!,
          ),
        );
        if (time != null) {
          final totalMinutes = time.hour * 60 + time.minute;
          if (totalMinutes > 0) setState(() => _selectedMinutes = totalMinutes);
        }
      },
      icon: const Icon(Icons.access_time_rounded, size: 18),
      label: const Text('Custom Time'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildActionButton(bool isActive, timerService) {
    final canStart = _selectedMinutes != null && _selectedMinutes! > 0;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: canStart || isActive
            ? () {
                if (isActive) {
                  timerService.cancel();
                } else {
                  timerService.start(
                    _selectedMinutes!,
                    onComplete: () {
                      ref.read(audioServiceProvider).pause();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sleep timer ended — playback paused')),
                        );
                      }
                    },
                  );
                  timerService.saveLastTimer(_selectedMinutes!);
                }
                setState(() {});
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? AppColors.error : AppColors.accent,
          disabledBackgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: Text(
          isActive ? 'Cancel Timer' : 'Start Timer',
          style: AppTextStyles.labelLarge.copyWith(
            color: canStart || isActive ? AppColors.background : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
