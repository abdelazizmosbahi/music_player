import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/main_navigation_shell.dart';
import 'features/permission_gate.dart';

class LocalWaveApp extends ConsumerStatefulWidget {
  const LocalWaveApp({super.key});

  @override
  ConsumerState<LocalWaveApp> createState() => _LocalWaveAppState();
}

class _LocalWaveAppState extends ConsumerState<LocalWaveApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Dismiss splash as soon as first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocalWave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _showSplash ? const _SplashScreen() : const PermissionGate(
        child: MainNavigationShell(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_rounded, color: Color(0xFF1ED760), size: 80),
            SizedBox(height: 16),
            Text('LocalWave', style: TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700,
            )),
            SizedBox(height: 8),
            Text('Your music, your way', style: TextStyle(
              color: Color(0xFF727272), fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }
}
