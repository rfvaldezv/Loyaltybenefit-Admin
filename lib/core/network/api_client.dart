import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio(BaseOptions(
    //baseUrl: 'https://api.loyaltybenefit.com',
    baseUrl: 'http://localhost:5265',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> get(String path) async {
    return _dio.get(path);
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response> getTenants() async {
    return _dio.get('/api/tenants');
  }

  Future<Response> createRule({
    required String tenantId,
    required double amountThreshold,
    required int points,
  }) async {
    return _dio.post('/api/rules',
      data: {
        'tenantId': tenantId,
        'amountThreshold': amountThreshold,
        'points': points,
      }
    );
  }

  Future<Response> getCustomers(String tenantId) async {
    return _dio.get('/api/customers',
      options: Options(
        headers: {
          'X-Tenant-Id': tenantId,
        }
      )
    );
  }

  Future<Response> createCustomer({
    required String name,
    required String email,
    required String tenantId,
    String? phone
  }) async {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Huésped';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return _dio.post('/api/customers',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      options: Options(
        headers: {
          'X-Tenant-Id': tenantId,
        }
      )
    );
  }

  Future<Response> createStay({
    required String tenantId,
    required String guestId,
    required double amount,
  }) async {
    return _dio.post('/api/loyalty/earn',
      data: {
        'guestId': guestId,
        'amount': amount,
      },
      options: Options(
        headers: {
          'X-Tenant-Id': tenantId,
        }
      )
    );
  }

  Future<Response> adjustPoints(String guestId, String tenantId, int points, String reason) {
    return _dio.post(
      '/api/customers/$guestId/adjust-points',
      data: {
        'points': points,
        'reason': reason,
      },
      options: Options(
        headers: {
          'X-Tenant-Id': tenantId,
        }
      )
    );
  }

  Future<Response> uploadLogo(String tenantId, String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    return _dio.post('/api/tenants/$tenantId/upload-logo', 
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  Future<Response> uploadLogoBytes(String tenantId, Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    return _dio.post('/api/tenants/$tenantId/upload-logo', 
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  Future<Response> getCorporateAnalytics() {
    return _dio.get('/api/analytics/corporate');
  }

  Future<Response> getProperties() {
    return _dio.get('/api/portal/properties');
  }

  Future<Response> getAnalytics({String? propertyId}) {
    return _dio.get('/api/analytics/corporate', queryParameters: {
      if (propertyId != null) 'propertyId': propertyId,
    });
  }
}
