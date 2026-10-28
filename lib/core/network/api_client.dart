import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  final Dio _dio;
  String? _userRole;
  String? _userPropertyId;
  String? _userEmail;

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5265', // Cambiar a https://api.loyaltybenefit.com en prod
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
    _userRole = null;
    _userPropertyId = null;
    _userEmail = null;
  }

  void setSessionData(String role, String? propertyId, String email) {
    _userRole = role;
    _userPropertyId = propertyId;
    _userEmail = email;
  }

  String? get userRole => _userRole;
  String? get userPropertyId => _userPropertyId;
  String? get userEmail => _userEmail;

  Future<Response> post(String path, {dynamic data}) async => _dio.post(path, data: data);
  Future<Response> get(String path) async => _dio.get(path);

  // TENANTS
  Future<Response> getTenants() => _dio.get('/api/tenants');
  Future<Response> getTenantById(String id) => _dio.get('/api/tenants/$id');

  Future<Response> uploadLogoBytes(String tenantId, Uint8List bytes, String fileName) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return _dio.post('/api/tenants/$tenantId/upload-logo', 
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
  }

  // CLIENTES
  Future<Response> getCustomers(String tenantId) async {
    return _dio.get('/api/customers', options: Options(headers: {'X-Tenant-Id': tenantId}));
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
      options: Options(headers: {'X-Tenant-Id': tenantId})
    );
  }

  Future<Response> adjustPoints(String guestId, String tenantId, int points, String reason) {
    return _dio.post('/api/customers/$guestId/adjust-points', 
      data: {'points': points, 'reason': reason},
      options: Options(headers: {'X-Tenant-Id': tenantId})
    );
  }

  // ESTANCIAS Y REGLAS
  Future<Response> createStay({
    required String tenantId,
    required String guestId,
    required double amount,
  }) async {
    return _dio.post('/api/loyalty/earn',
      data: {'guestId': guestId, 'amount': amount},
      options: Options(headers: {'X-Tenant-Id': tenantId})
    );
  }

  Future<Response> createRule({
    required String tenantId,
    required double amountThreshold,
    required int points,
  }) async {
    return _dio.post('/api/rules',
      data: {'tenantId': tenantId, 'amountThreshold': amountThreshold, 'points': points}
    );
  }

  // PROPIEDADES
  Future<Response> getProperties() => _dio.get('/api/properties');
  
  Future<Response> createProperty({required String name, required String code}) {
    return _dio.post('/api/properties', data: {'name': name, 'code': code});
  }

  Future<Response> updateProperty({required String id, required String name, required String code}) {
    return _dio.put('/api/properties/$id', data: {'name': name, 'code': code});
  }

  Future<Response> deleteProperty(String id) => _dio.delete('/api/properties/$id');

  // USUARIOS
  Future<Response> getUsers() => _dio.get('/api/users');
  
  Future<Response> createUser({required String email, required String password, required String role}) {
    return _dio.post('/api/users', data: {'email': email, 'password': password, 'role': role});
  }

  Future<Response> updateUser({required String id, required String role, required bool isActive, String? password}) {
    return _dio.put('/api/users/$id', data: {
      'role': role,
      'isActive': isActive,
      if (password != null) 'password': password,
    });
  }

  Future<Response> deleteUser(String id) => _dio.delete('/api/users/$id');

  // ANALÍTICA
  Future<Response> getAnalytics({String? propertyId}) {
    return _dio.get('/api/analytics/corporate', queryParameters: {
      if (propertyId != null) 'propertyId': propertyId,
    });
  }
}
