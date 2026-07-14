import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'app.dart';
import 'providers/media_provider.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';

/// Global audio service instance — starts as stub, upgraded after init.
late AudioPlayerService audioService;

/// Global provider container so we can update audio service after init.
late final ProviderContainer _container;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF121212),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Start with a stub so the UI can render immediately.
  audioService = AudioPlayerService.createStub();

  _container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const LocalWaveApp(),
    ),
  );

  // Initialize audio service AFTER the first frame renders.
  _initAudioService();
}

Future<void> _initAudioService() async {
  try {
    final audioHandler = await AudioService.init<LocalWaveAudioHandler>(
      builder: () => LocalWaveAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.localwave.audio',
        androidNotificationChannelName: 'LocalWave Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/notification_icon',
        fastForwardInterval: Duration(seconds: 10),
        rewindInterval: Duration(seconds: 10),
      ),
    ).timeout(const Duration(seconds: 15));

    audioService = AudioPlayerService(audioHandler);
    _container.read(audioServiceReadyProvider.notifier).setReady(audioService);
  } catch (e) {
    debugPrint('AudioService init failed: $e');
    // Keep using the stub — app works, just no playback.
  }
}
