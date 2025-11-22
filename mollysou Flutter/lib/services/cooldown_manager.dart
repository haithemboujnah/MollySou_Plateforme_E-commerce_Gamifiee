// lib/utils/cooldown_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CooldownManager {
  static final CooldownManager _instance = CooldownManager._internal();
  factory CooldownManager() => _instance;
  CooldownManager._internal();

  // Stream controllers for cooldown updates
  final StreamController<Duration> _wheelCooldownController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _puzzleCooldownController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _videoCooldownController = StreamController<Duration>.broadcast();

  // Getters for streams
  Stream<Duration> get wheelCooldownStream => _wheelCooldownController.stream;
  Stream<Duration> get puzzleCooldownStream => _puzzleCooldownController.stream;
  Stream<Duration> get videoCooldownStream => _videoCooldownController.stream;

  // Update cooldown methods
  void updateWheelCooldown(Duration duration) {
    print('Updating wheel cooldown: $duration');
    _wheelCooldownController.add(duration);
  }

  void updatePuzzleCooldown(Duration duration) {
    print('Updating puzzle cooldown: $duration');
    _puzzleCooldownController.add(duration);
  }

  void updateVideoCooldown(Duration duration) {
    print('Updating video cooldown: $duration');
    _videoCooldownController.add(duration);
  }

  // Save cooldown to local storage
  Future<void> saveLocalCooldown(String type, Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownEndTime = DateTime.now().add(duration);
    await prefs.setInt('last${type}Time', cooldownEndTime.millisecondsSinceEpoch);
    print('Saved local cooldown for $type: $duration');
  }

  // Load cooldown from local storage
  Future<Duration?> getLocalCooldown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTimeMillis = prefs.getInt('last${type}Time');

    if (lastTimeMillis != null) {
      final cooldownEndTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMillis);
      final now = DateTime.now();

      if (now.isBefore(cooldownEndTime)) {
        final remaining = cooldownEndTime.difference(now);
        print('Loaded local cooldown for $type: $remaining');
        return remaining;
      } else {
        print('Local cooldown for $type has expired');
        // Remove expired cooldown
        await prefs.remove('last${type}Time');
      }
    }
    return null;
  }

  void dispose() {
    _wheelCooldownController.close();
    _puzzleCooldownController.close();
    _videoCooldownController.close();
  }
}