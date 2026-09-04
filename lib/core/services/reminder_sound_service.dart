import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderTuneModel {
  final String id;
  final String title;
  final String subtitle;
  final String assetName; // e.g. 'sounds/chime.wav' relative to assets
  final bool isDefault;

  const ReminderTuneModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetName,
    this.isDefault = false,
  });

  String get fullAssetPath => 'assets/$assetName';
}

class ReminderSoundService {
  ReminderSoundService._();
  static final ReminderSoundService instance = ReminderSoundService._();

  static const String _prefKeySelectedTune = 'selected_reminder_tune_id';
  static const String defaultTuneId = 'chime';

  AudioPlayer? _playerInstance;

  AudioPlayer? get _player {
    if (_playerInstance != null) return _playerInstance;
    try {
      _playerInstance = AudioPlayer();
      return _playerInstance;
    } catch (e) {
      debugPrint('AudioPlayer initialization skipped: $e');
      return null;
    }
  }

  bool _isInitialized = false;

  /// Available Reminder Tunes
  static const List<ReminderTuneModel> availableTunes = [
    ReminderTuneModel(
      id: 'chime',
      title: 'Chime (Default)',
      subtitle: 'Gentle two-tone chime',
      assetName: 'sounds/chime.wav',
      isDefault: true,
    ),
    ReminderTuneModel(
      id: 'digital_bell',
      title: 'Digital Bell',
      subtitle: 'Crisp digital bell chime',
      assetName: 'sounds/digital_bell.wav',
    ),
    ReminderTuneModel(
      id: 'pulse_alert',
      title: 'Pulse Alert',
      subtitle: 'Modern triple-pulse alert',
      assetName: 'sounds/pulse_alert.wav',
    ),
    ReminderTuneModel(
      id: 'gentle_chime',
      title: 'Gentle Chime',
      subtitle: 'Soft three-tone melody',
      assetName: 'sounds/gentle_chime.wav',
    ),
    ReminderTuneModel(
      id: 'buzzer_alert',
      title: 'Buzzer Alert',
      subtitle: 'Audible urgent compliance tone',
      assetName: 'sounds/buzzer_alert.wav',
    ),
  ];

  /// Notifier for currently selected tune ID
  final ValueNotifier<String> selectedTuneIdNotifier =
      ValueNotifier<String>(defaultTuneId);

  /// Notifier for tune currently playing a preview (null if idle)
  final ValueNotifier<String?> currentlyPlayingTuneIdNotifier =
      ValueNotifier<String?>(null);

  String get selectedTuneId => selectedTuneIdNotifier.value;

  ReminderTuneModel get selectedTune {
    return availableTunes.firstWhere(
      (t) => t.id == selectedTuneId,
      orElse: () => availableTunes.first,
    );
  }

  /// Initialize service and restore user's saved tune preference
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKeySelectedTune) ?? defaultTuneId;
      if (availableTunes.any((t) => t.id == savedId)) {
        selectedTuneIdNotifier.value = savedId;
      }

      // Listen for player completion to reset preview state if player available
      final player = _player;
      if (player != null) {
        player.onPlayerComplete.listen((_) {
          currentlyPlayingTuneIdNotifier.value = null;
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('ReminderSoundService.init error: $e');
    }
  }

  /// Select a new tune and persist preference
  Future<void> selectTune(String tuneId) async {
    if (!availableTunes.any((t) => t.id == tuneId)) return;

    selectedTuneIdNotifier.value = tuneId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedTune, tuneId);
    } catch (e) {
      debugPrint('ReminderSoundService.selectTune error: $e');
    }
  }

  /// Play the selected tune continuously for compliance alert
  Future<void> playAlertTune() async {
    await init();
    try {
      final player = _player;
      if (player == null) return;

      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      final tune = selectedTune;
      currentlyPlayingTuneIdNotifier.value = tune.id;
      await player.play(AssetSource(tune.assetName));
    } catch (e) {
      debugPrint('ReminderSoundService.playAlertTune error: $e');
    }
  }

  /// Preview any tune once (stopping previous sound if any)
  Future<void> previewTune(String tuneId) async {
    await init();
    final tune = availableTunes.firstWhere(
      (t) => t.id == tuneId,
      orElse: () => availableTunes.first,
    );

    try {
      // If the same tune is already previewing, toggle stop
      if (currentlyPlayingTuneIdNotifier.value == tuneId) {
        await stop();
        return;
      }

      final player = _player;
      if (player == null) return;

      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      currentlyPlayingTuneIdNotifier.value = tune.id;
      await player.play(AssetSource(tune.assetName));
    } catch (e) {
      debugPrint('ReminderSoundService.previewTune error: $e');
      currentlyPlayingTuneIdNotifier.value = null;
    }
  }

  /// Stop any currently playing tune
  Future<void> stop() async {
    try {
      final player = _player;
      if (player != null) {
        await player.stop();
      }
    } catch (e) {
      debugPrint('ReminderSoundService.stop error: $e');
    } finally {
      currentlyPlayingTuneIdNotifier.value = null;
    }
  }

  /// Dispose player resources
  Future<void> dispose() async {
    await stop();
    try {
      await _player?.dispose();
    } catch (_) {}
    _playerInstance = null;
  }
}
