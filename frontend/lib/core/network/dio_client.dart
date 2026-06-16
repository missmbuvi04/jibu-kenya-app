import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient(storage);
});

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;

  DioClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 400, 
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio, this),
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (o) => print('[DIO] $o'),
        ),
    ]);
  }

  Dio get instance => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> postFormData(
    String path, {
    required FormData formData,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
        'Connection timed out. Make sure your backend is running and your IP address is correct.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'Cannot reach the server. Check that:\n'
        '1. Django is running (python manage.py runserver 0.0.0.0:8000)\n'
        '2. Your phone and laptop are on the same Wi-Fi\n'
        '3. The IP address in api_constants.dart is correct',
      );
    }
    return Exception(parseDjangoError(e));
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;
  final DioClient _client;

  _AuthInterceptor(this._storage, this._dio, this._client);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login and register endpoints
    final skipAuth = options.path.contains('/login/') ||
        options.path.contains('/register/') ||
        options.path.contains('/token/refresh/');

    if (!skipAuth) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Handle Django validation errors that return 400 with error maps
    if (response.statusCode == 400) {
      final error = parseDjangoError(response.data);
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: error,
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_client._isRefreshing) {
      _client._isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _storage.clearAll();
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          ApiConstants.tokenRefresh,
          data: {'refresh': refreshToken},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final newAccessToken = response.data['access'] as String?;
        if (newAccessToken == null) {
          await _storage.clearAll();
          handler.next(err);
          return;
        }

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await _storage.clearAll();
        handler.next(err);
      } finally {
        _client._isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}

// Parse Django error responses into readable strings
String parseDjangoError(dynamic error) {
  try {
    Map<String, dynamic>? data;

    if (error is DioException) {
      data = error.response?.data as Map<String, dynamic>?;
    } else if (error is Map<String, dynamic>) {
      data = error;
    }

    if (data == null) return 'Something went wrong. Please try again.';

    if (data.containsKey('detail')) {
      return data['detail'].toString();
    }

    if (data.containsKey('non_field_errors')) {
      final errors = data['non_field_errors'];
      if (errors is List && errors.isNotEmpty) return errors.first.toString();
    }

    // Return first field error
    for (final key in data.keys) {
      final value = data[key];
      if (value is List && value.isNotEmpty) {
        return '$key: ${value.first}';
      }
      if (value is String) return '$key: $value';
    }

    return 'Something went wrong. Please try again.';
  } catch (_) {
    return 'Something went wrong. Please try again.';
  }
}