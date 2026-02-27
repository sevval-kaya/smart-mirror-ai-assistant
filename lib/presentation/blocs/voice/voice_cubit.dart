import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../data/datasources/remote/ai_remote_datasource.dart';

// ── State ──────────────────────────────────────────────────────────────────

abstract class VoiceState extends Equatable {
  const VoiceState();
  @override
  List<Object?> get props => [];
}

class VoiceIdle extends VoiceState {
  const VoiceIdle();
}

class VoiceInitializing extends VoiceState {
  const VoiceInitializing();
}

class VoiceListening extends VoiceState {
  final String partialTranscript;
  const VoiceListening({this.partialTranscript = ''});
  @override
  List<Object?> get props => [partialTranscript];
}

class VoiceProcessing extends VoiceState {
  final String transcript;
  const VoiceProcessing({required this.transcript});
  @override
  List<Object?> get props => [transcript];
}

class VoiceSpeaking extends VoiceState {
  final String response;
  const VoiceSpeaking({required this.response});
  @override
  List<Object?> get props => [response];
}

class VoiceError extends VoiceState {
  final Failure failure;
  const VoiceError(this.failure);
  @override
  List<Object?> get props => [failure];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

/// Ses tanıma → AI işleme → TTS konuşma akışını yöneten Cubit.
///
/// Akış:
///   [Mikrofon] → speech_to_text → transcript → ApiService (NGINX)
///   → AI yanıtı → flutter_tts → [Hoparlör]
class VoiceCubit extends Cubit<VoiceState> {
  final stt.SpeechToText _speechToText;
  final FlutterTts _tts;
  final IAiRemoteDataSource _aiDataSource;

  bool _isInitialized = false;

  VoiceCubit({
    required stt.SpeechToText speechToText,
    required FlutterTts tts,
    required IAiRemoteDataSource aiDataSource,
  })  : _speechToText = speechToText,
        _tts = tts,
        _aiDataSource = aiDataSource,
        super(const VoiceIdle()) {
    _configureTts();
  }

  // ── TTS Yapılandırması ────────────────────────────────────────────────────

  void _configureTts() {
    _tts.setLanguage('tr-TR');
    _tts.setSpeechRate(1.0);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (!isClosed) emit(const VoiceIdle());
    });
  }

  void updateTtsSettings({double? speed, double? pitch}) {
    if (speed != null) _tts.setSpeechRate(speed);
    if (pitch != null) _tts.setPitch(pitch);
  }

  // ── Başlat / Durdur ───────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    emit(const VoiceInitializing());
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          if (!isClosed) emit(VoiceError(VoiceFailure(error.errorMsg)));
        },
        onStatus: (status) {
          // dinleme durumu izleme
        },
      );
      if (_isInitialized) {
        emit(const VoiceIdle());
      } else {
        emit(const VoiceError(VoiceFailure('Mikrofon başlatılamadı.')));
      }
    } catch (e) {
      emit(const VoiceError(PermissionFailure()));
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    emit(const VoiceListening());

    // speech_to_text v7 — SpeechListenOptions kullanılır
    await _speechToText.listen(
      localeId: 'tr_TR',
      listenFor: AppConstants.voiceListenTimeout,
      pauseFor: AppConstants.voicePauseThreshold,
      onResult: (result) {
        if (!isClosed) {
          if (result.finalResult) {
            _processTranscript(result.recognizedWords);
          } else {
            emit(VoiceListening(partialTranscript: result.recognizedWords));
          }
        }
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    if (!isClosed) emit(const VoiceIdle());
  }

  // ── AI İşleme ─────────────────────────────────────────────────────────────

  Future<void> _processTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      emit(const VoiceIdle());
      return;
    }

    emit(VoiceProcessing(transcript: transcript));

    try {
      final response = await _aiDataSource.processVoiceCommand(transcript);
      await _speak(response);
    } on Exception {
      await _speak(_buildOfflineResponse(transcript));
    }
  }

  Future<void> _speak(String text) async {
    emit(VoiceSpeaking(response: text));
    await _tts.speak(text);
  }

  /// Bağlantısız (offline) mod için basit kural tabanlı yanıtlar.
  String _buildOfflineResponse(String transcript) {
    final lower = transcript.toLowerCase();
    if (lower.contains('merhaba') || lower.contains('selam')) {
      return 'Merhaba! Size nasıl yardımcı olabilirim?';
    }
    if (lower.contains('görev') || lower.contains('yapılacak')) {
      return 'Görev listenize bakabilirsiniz.';
    }
    if (lower.contains('saat') || lower.contains('zaman')) {
      final now = DateTime.now();
      return 'Saat ${now.hour}:${now.minute.toString().padLeft(2, '0')}.';
    }
    return 'Üzgünüm, şu an internet bağlantım yok. Lütfen tekrar deneyin.';
  }

  Future<void> speak(String text) async => _speak(text);

  Future<void> stopSpeaking() async {
    await _tts.stop();
    if (!isClosed) emit(const VoiceIdle());
  }

  @override
  Future<void> close() async {
    await _speechToText.cancel();
    await _tts.stop();
    return super.close();
  }
}
