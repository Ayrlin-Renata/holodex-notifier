import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

// Type definition for the function that will fetch the API key
typedef ApiKeyGetter = Future<String?> Function();

// --- Interceptors ---

// Interceptor to inject the API Key
class ApiKeyInterceptor extends Interceptor {
  final ApiKeyGetter _apiKeyGetter;
  // TODO: Add fallback developer key from config/environment if needed
  final String? _fallbackDeveloperKey = null; // Example: const String.fromEnvironment('DEV_API_KEY');

  ApiKeyInterceptor(this._apiKeyGetter);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Fetch the API key asynchronously
    String? apiKey = await _apiKeyGetter();

    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers['X-APIKEY'] = apiKey;
      if (kDebugMode) {
        print('[Dio Interceptor] Using user API Key.');
      }
    } else if (_fallbackDeveloperKey != null && _fallbackDeveloperKey.isNotEmpty) {
      options.headers['X-APIKEY'] = _fallbackDeveloperKey;
       if (kDebugMode) {
         print('[Dio Interceptor] Using fallback developer Key.');
       }
    } else {
       if (kDebugMode) {
         print('[Dio Interceptor] Warning: No API Key available for request.');
       }
       // Decide if request should proceed without a key - Holodex might allow some limited access
       // handler.reject(DioException(requestOptions: options, message: "API Key required"));
    }
    super.onRequest(options, handler);
  }
}

// --- Dio Client Setup ---

class DioClient {
  late final Dio _dio;
  final ApiKeyGetter _apiKeyGetter;

  DioClient({required ApiKeyGetter apiKeyGetter}) : _apiKeyGetter = apiKeyGetter {
    final options = BaseOptions(
      baseUrl: 'https://holodex.net/api/v2', // Base Holodex API URL
      connectTimeout: const Duration(seconds: 15), // Increased timeout slightly
      receiveTimeout: const Duration(seconds: 15), // Increased timeout slightly
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio = Dio(options);

    // Add Interceptors
    _dio.interceptors.add(ApiKeyInterceptor(_apiKeyGetter)); // Inject API Key via getter

    // Add Logging Interceptor (only in debug mode)
    if (kDebugMode) { // Use kDebugMode to only add logging in debug builds
       _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true, // Set to false if responses are too large
        error: true,
        logPrint: (object) => print('[Dio Log] $object'), // Simple redirection to print
      ));
    }

    // TODO: Add RetryInterceptor (e.g., dio_smart_retry)
    // _dio.interceptors.add(RetryInterceptor(dio: _dio, logPrint: print, retries: 3));

    // TODO: Add ErrorHandlingInterceptor
    // _dio.interceptors.add(ErrorHandlingInterceptor());
  }

  // Getter to expose the configured Dio instance
  Dio get instance => _dio;
}