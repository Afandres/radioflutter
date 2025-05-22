import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  RadioAudioHandler() {
    _player.playerStateStream.listen((state) {
      if (state.playing) {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.pause, MediaControl.stop],
          playing: true,
          processingState: AudioProcessingState.ready,
        ));
      } else {
        playbackState.add(playbackState.value.copyWith(
          controls: [MediaControl.play, MediaControl.stop],
          playing: false,
          processingState: AudioProcessingState.ready,
        ));
      }
    });
  }

  Future<void> playStream(String url) async {
    try {
      await _player.setUrl(url);
      _player.play();
    } catch (e) {
      // Manejar errores
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    return super.stop();
  }
}
