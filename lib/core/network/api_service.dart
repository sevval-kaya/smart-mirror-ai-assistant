import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../security/security_layer.dart';

/// NGINX API Gateway ile güvenli (TLS) iletişim katmanı.
///
/// Tüm istekler bu servis üzerinden geçer:
///  1. Kullanıcı onayı (consent) zorunluluğu
///  2. Bearer token enjeksiyonu
///  3. Cihaz kimliği header'ı
///  4. Self-signed sertifika desteği (geliştirme ortamı)
class ApiService {
  late final Dio _dio;
  final SecurityLayer _security;

  ApiService({required SecurityLayer security}) : _security = security {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.headerContentType,
          'Accept': ApiConstants.headerAccept,
          ApiConstants.headerApiVersion: ApiConstants.apiVersion,
        },
      ),
    );

    _setupInterceptors();
    _setupTlsConfiguration();
  }

  // ── TLS Yapılandırması ────────────────────────────────────────────────────

  void _setupTlsConfiguration() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      // Geliştirme ortamında self-signed sertifikalara izin ver.
      // ÜRETİMDE bu blok kaldırılmalı ve sertifika parmak izi doğrulaması
      // aşağıdaki onBadCertificate callback'ine eklenmeli.
      client.badCertificateCallback = (cert, host, port) {
        const bool isDev = !bool.fromEnvironment('dart.vm.product');
        if (isDev) return true; // Yalnızca geliştirme ortamı

        // Üretim: Sertifika parmak izini doğrula
        return SecurityLayer.verifyCertificateFingerprint(
          cert.der,
          expectedSha256: const String.fromEnvironment('TLS_CERT_FINGERPRINT'),
        );
      };
      return client;
    };
  }

  // ── Interceptor'lar ───────────────────────────────────────────────────────

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      // Auth token & device ID enjeksiyonu
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _security.getAuthToken();
          final deviceId = await _security.getDeviceId();

          if (token != null) {
            options.headers[ApiConstants.headerAuthorization] =
                'Bearer $token';
          }
          options.headers[ApiConstants.headerDeviceId] = deviceId;

          return handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            // Token süresi dolmuş — oturumu temizle
            _security.clearSession();
          }
          return handler.next(err);
        },
      ),

      // Geliştirme ortamı için istek/yanıt günlüğü
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        enabled: !const bool.fromEnvironment('dart.vm.product'),
      ),
    ]);
  }

  // ── Genel HTTP Metodları ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.post(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    await _security.requireConsent();
    try {
      final response = await _dio.put(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> delete(String endpoint) async {
    await _security.requireConsent();
    try {
      await _dio.delete(endpoint);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── AI Özelinde: Ses Komutu Gönder ───────────────────────────────────────

  /// Mikrofon metnini NGINX gateway üzerinden TensorFlow modeline iletir.
  Future<Map<String, dynamic>> sendVoiceCommand(String transcript) async {
    return post(
      ApiConstants.voiceCommandEndpoint,
      body: {
        'transcript': transcript,
        'timestamp': DateTime.now().toIso8601String(),
        'locale': 'tr_TR',
      },
    );
  }

  /// Ham metin sorgusunu AI inference endpoint'e gönderir.
  Future<Map<String, dynamic>> inferAi(String prompt) async {
    return post(
      ApiConstants.aiInferenceEndpoint,
      body: {
        'prompt': prompt,
        'max_tokens': 512,
        'temperature': 0.7,
      },
    );
  }

  // ── Yardımcılar ───────────────────────────────────────────────────────────

  Map<String, dynamic> _handleResponse(Response response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      return (response.data as Map<String, dynamic>?) ?? {};
    }
    throw ServerException(
      message: response.statusMessage ?? 'Sunucu hatası',
      statusCode: statusCode,
    );
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException('Bağlantı zaman aşımına uğradı.');
      case DioExceptionType.connectionError:
        return const NetworkException('Sunucuya ulaşılamıyor.');
      case DioExceptionType.badResponse:
        return ServerException(
          message: e.response?.statusMessage ?? 'Sunucu hatası',
          statusCode: e.response?.statusCode,
        );
      default:
        return NetworkException(e.message ?? 'Bilinmeyen ağ hatası.');
    }
  }
}
