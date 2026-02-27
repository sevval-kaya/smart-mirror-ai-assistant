/// NGINX API Gateway ve yapay zeka modeli için endpoint sabitleri.
class ApiConstants {
  ApiConstants._();

  // ── Base URLs ─────────────────────────────────────────────────────────────
  /// Geliştirme ortamı (Docker Compose iç ağı)
  static const String _devBaseUrl = 'https://192.168.1.100:8443';

  /// Üretim ortamı (Gerçek sunucu adresiyle değiştirilecek)
  static const String _prodBaseUrl = 'https://api.smartmirror.local';

  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  static String get baseUrl => _isProduction ? _prodBaseUrl : _devBaseUrl;

  // ── NGINX Gateway Endpoint'leri ───────────────────────────────────────────
  static const String aiInferenceEndpoint = '/api/v1/ai/infer';
  static const String aiStatusEndpoint = '/api/v1/ai/status';
  static const String voiceCommandEndpoint = '/api/v1/voice/process';
  static const String userSyncEndpoint = '/api/v1/users/sync';

  // ── Timeout Süreleri ──────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ── HTTP Headers ──────────────────────────────────────────────────────────
  static const String headerContentType = 'application/json';
  static const String headerAccept = 'application/json';
  static const String headerAuthorization = 'Authorization';
  static const String headerDeviceId = 'X-Device-ID';
  static const String headerApiVersion = 'X-API-Version';
  static const String apiVersion = 'v1';
}
