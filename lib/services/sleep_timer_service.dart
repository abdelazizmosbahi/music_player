import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback type for when the sleep timer fires.
typedef OnTimerComplete = void Function();

class SleepTimerService {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isActive = false;
  OnTimerComplete? _onComplete;

  final StreamController<bool> _activeController = StreamController<bool>.broadcast();
  final StreamController<int> _remainingController = StreamController<int>.broadcast();

  Stream<bool> get isActiveStream => _activeController.stream;
  Stream<int> get remainingSecondsStream => _remainingController.stream;
  bool get isActive => _isActive;
  int get remainingSeconds => _remainingSeconds;

  /// Starts a sleep timer. [onComplete] is called when the timer reaches zero.
  void start(int minutes, {OnTimerComplete? onComplete}) {
    cancel();
    _remainingSeconds = minutes * 60;
    _isActive = true;
    _onComplete = onComplete;
    _activeController.add(true);
    _remainingController.add(_remainingSeconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        cancel();
        _onComplete?.call();
      }
    });
  }

  void cancel() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _remainingSeconds = 0;
    _isActive = false;
    _activeController.add(false);
    _remainingController.add(0);
  }

  String get formattedRemaining {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> saveLastTimer(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sleep_timer', minutes);
  }

  Future<int> getLastTimer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_sleep_timer') ?? 30;
  }

  void dispose() {
    cancel();
    _activeController.close();
    _remainingController.close();
  }
}
