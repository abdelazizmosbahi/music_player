import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'app.dart';
import 'services/audio_handler.dart';
import 'services/audio_player_service.dart';
import 'providers/media_provider.dart';

late AudioPlayerService audioService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF121212),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize audio service
  final audioHandler = await AudioService.init<LocalWaveAudioHandler>(
    builder: () => LocalWaveAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.localwave.audio',
      androidNotificationChannelName: 'LocalWave Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );

  audioService = AudioPlayerService(audioHandler);

  runApp(
    ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(audioService),
      ],
      child: const LocalWaveApp(),
    ),
  );
}
