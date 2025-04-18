import 'package:dio/dio.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';

typedef ApiKeyGetter = Future<String?> Function();

class ApiKeyInterceptor extends Interceptor {
  final ApiKeyGetter _apiKeyGetter;
  final ILoggingService _logger;
  final String? _fallbackDeveloperKey = null;

  ApiKeyInterceptor(this._apiKeyGetter, this._logger);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    String? apiKey = await _apiKeyGetter();
    _logger.debug('[Dio Interceptor] Retrieved API Key: ${apiKey != null ? 'present' : 'null'}');

    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers['X-APIKEY'] = apiKey;
      _logger.debug('[Dio Interceptor] Using user API Key.');
    } else if (_fallbackDeveloperKey != null && _fallbackDeveloperKey.isNotEmpty) {
      options.headers['X-APIKEY'] = _fallbackDeveloperKey;
      _logger.debug('[Dio Interceptor] Using fallback developer Key.');
    } else {
      _logger.warning('[Dio Interceptor] Warning: No API Key available for request.');
    }
    super.onRequest(options, handler);
  }
}

class DioClient {
  late final Dio _dio;
  final ApiKeyGetter _apiKeyGetter;
  final ILoggingService _logger;

  DioClient({required ApiKeyGetter apiKeyGetter, required ILoggingService logger}) : _apiKeyGetter = apiKeyGetter, _logger = logger {
    final options = BaseOptions(
      baseUrl: 'https://holodex.net/api/v2',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'User-Agent': 'HolodexNotifierApp'},
    );
    _dio = Dio(options);

    _dio.interceptors.add(ApiKeyInterceptor(_apiKeyGetter, _logger));

    // Always add LogInterceptor, removing the kDebugMode check
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) => _logger.debug('[Dio Log] $object'), // Using debug level for Dio logs
      ),
    );
  }

  Dio get instance => _dio;
}
