import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ==================== SHOPIFY BACKEND API SERVICE ====================
class ShopifyAuthApiService {
  late Dio _dio;
  static String _baseUrl =
      'https://your-shopify-backend.com/api'; // Update with your backend URL
  String? _accessToken;

  // Singleton pattern
  static final ShopifyAuthApiService _instance =
      ShopifyAuthApiService._internal();
  factory ShopifyAuthApiService() => _instance;

  ShopifyAuthApiService._internal() {
    _dio = Dio();
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.add(_getLogInterceptor());
    _dio.interceptors.add(_getAuthInterceptor());
    _dio.interceptors.add(_getErrorInterceptor());
  }

  LogInterceptor _getLogInterceptor() {
    return LogInterceptor(
      request: kDebugMode,
      requestBody: kDebugMode,
      requestHeader: kDebugMode,
      // response: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: kDebugMode,
      logPrint: (obj) {
        if (kDebugMode) {
          debugPrint('🛍️ Shopify Auth API: $obj');
        }
      },
    );
  }

  InterceptorsWrapper _getAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Add access token if available
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized - token expired
        if (error.response?.statusCode == 401) {
          _accessToken = null;
          // You might want to trigger a logout event here
          await _handleAuthFailure();
        }
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _getErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        _handleHttpError(error);
        handler.next(error);
      },
    );
  }

  void _handleHttpError(DioException error) {
    switch (error.response?.statusCode) {
      case 400:
        throw ShopifyAuthException(
            'Bad request: ${_extractErrorMessage(error.response?.data)}');
      case 401:
        throw ShopifyAuthException('Invalid credentials. Please try again.');
      case 403:
        throw ShopifyAuthException('Access forbidden');
      case 404:
        throw ShopifyAuthException('Service not found');
      case 422:
        throw ShopifyAuthException(
            'Validation error: ${_extractValidationErrors(error.response?.data)}');
      case 429:
        throw ShopifyAuthException(
            'Too many requests. Please try again later.');
      case 500:
        throw ShopifyAuthException('Server error. Please try again later.');
      default:
        throw ShopifyAuthException('Connection error: ${error.message}');
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      return data['message'] ?? data['error'] ?? 'Unknown error';
    }
    return data?.toString() ?? 'Unknown error';
  }

  String _extractValidationErrors(dynamic data) {
    if (data is Map && data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is Map) {
        return errors.values.map((e) => e.toString()).join(', ');
      } else if (errors is List) {
        return errors.map((e) => e.toString()).join(', ');
      }
    }
    return _extractErrorMessage(data);
  }

  // ==================== AUTHENTICATION METHODS ====================

  // Login/Signin
  Future<ShopifyLoginResponse> login(ShopifyLoginRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/login', // or '/signin', '/auth/signin' - adjust based on your backend
        data: request.toJson(),
      );

      final loginResponse = ShopifyLoginResponse.fromJson(response.data);

      // Store access token for future requests
      if (loginResponse.success && loginResponse.token != null) {
        _accessToken = loginResponse.token;
      }

      return loginResponse;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Register/Signup
  Future<ShopifySignupResponse> signup(ShopifySignupRequest request) async {
    try {
      final response = await _dio.post(
        '/auth/register', // or '/signup', '/auth/signup' - adjust based on your backend
        data: request.toJson(),
      );

      final signupResponse = ShopifySignupResponse.fromJson(response.data);

      // Store access token if registration includes auto-login
      if (signupResponse.success && signupResponse.token != null) {
        _accessToken = signupResponse.token;
      }

      return signupResponse;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _dio.post('/auth/logout');
      }
    } catch (e) {
      // Log error but don't throw - we want to clear local token regardless
      debugPrint('Logout API call failed: $e');
    } finally {
      _accessToken = null;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      return response.data['success'] ?? true;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    String? confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': newPassword,
          if (confirmPassword != null) 'password_confirmation': confirmPassword,
        },
      );

      return response.data['success'] ?? true;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Verify Email
  Future<bool> verifyEmail(String token) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {'token': token},
      );

      return response.data['success'] ?? true;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Resend Verification Email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      return response.data['success'] ?? true;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Get Current User Profile
  Future<ShopifyUser> getCurrentUser() async {
    if (_accessToken == null) {
      throw ShopifyAuthException('No access token available');
    }

    try {
      final response = await _dio.get('/auth/me'); // or '/user/profile'
      return ShopifyUser.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Update Profile
  Future<ShopifyUser> updateProfile(Map<String, dynamic> profileData) async {
    if (_accessToken == null) {
      throw ShopifyAuthException('No access token available');
    }

    try {
      final response = await _dio.put(
        '/auth/profile', // or '/user/profile'
        data: profileData,
      );

      return ShopifyUser.fromJson(response.data['user'] ?? response.data);
    } on DioException catch (e) {
      rethrow;
    }
  }

  // Change Password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (_accessToken == null) {
      throw ShopifyAuthException('No access token available');
    }

    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          if (confirmPassword != null)
            'new_password_confirmation': confirmPassword,
        },
      );

      return response.data['success'] ?? true;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // ==================== UTILITY METHODS ====================

  // Update base URL
  void updateBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
    _dio.options.baseUrl = baseUrl;
  }

  // Set access token manually
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  // Get current access token
  String? get accessToken => _accessToken;

  // Check if user is logged in
  bool get isLoggedIn => _accessToken != null;

  // Handle auth failure (implement based on your app's navigation)
  Future<void> _handleAuthFailure() async {
    // Implement navigation to login screen or show login dialog
    // This is app-specific implementation
    debugPrint('Authentication failed - redirecting to login');
  }
}

// ==================== MODELS ====================

// Login Request
class ShopifyLoginRequest {
  final String email;
  final String password;
  final bool rememberMe;
  final String? deviceToken; // For push notifications

  const ShopifyLoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'remember_me': rememberMe,
      if (deviceToken != null) 'device_token': deviceToken,
    };
  }
}

// Signup Request
class ShopifySignupRequest {
  final String email;
  final String password;
  final String? passwordConfirmation;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? dateOfBirth;
  final bool acceptsMarketing;
  final bool agreeToTerms;
  final String? deviceToken;

  const ShopifySignupRequest({
    required this.email,
    required this.password,
    this.passwordConfirmation,
    this.firstName,
    this.lastName,
    this.phone,
    this.dateOfBirth,
    this.acceptsMarketing = false,
    this.agreeToTerms = true,
    this.deviceToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (passwordConfirmation != null)
        'password_confirmation': passwordConfirmation,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      'accepts_marketing': acceptsMarketing,
      'agree_to_terms': agreeToTerms,
      if (deviceToken != null) 'device_token': deviceToken,
    };
  }
}

// Login Response
class ShopifyLoginResponse {
  final bool success;
  final String message;
  final String? token;
  final String? tokenType;
  final DateTime? expiresAt;
  final ShopifyUser? user;
  final Map<String, dynamic>? errors;

  const ShopifyLoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.tokenType,
    this.expiresAt,
    this.user,
    this.errors,
  });

  factory ShopifyLoginResponse.fromJson(Map<String, dynamic> json) {
    return ShopifyLoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? json['access_token'],
      tokenType: json['token_type'] ?? 'Bearer',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      user: json['user'] != null ? ShopifyUser.fromJson(json['user']) : null,
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'])
          : null,
    );
  }
}

// Signup Response
class ShopifySignupResponse {
  final bool success;
  final String message;
  final String? token;
  final String? tokenType;
  final DateTime? expiresAt;
  final ShopifyUser? user;
  final bool? needsVerification;
  final Map<String, dynamic>? errors;

  const ShopifySignupResponse({
    required this.success,
    required this.message,
    this.token,
    this.tokenType,
    this.expiresAt,
    this.user,
    this.needsVerification,
    this.errors,
  });

  factory ShopifySignupResponse.fromJson(Map<String, dynamic> json) {
    return ShopifySignupResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? json['access_token'],
      tokenType: json['token_type'] ?? 'Bearer',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      user: json['user'] != null ? ShopifyUser.fromJson(json['user']) : null,
      needsVerification: json['needs_verification'],
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'])
          : null,
    );
  }
}

// User Model
class ShopifyUser {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final DateTime? dateOfBirth;
  final bool isEmailVerified;
  final bool acceptsMarketing;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const ShopifyUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    this.dateOfBirth,
    this.isEmailVerified = false,
    this.acceptsMarketing = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ShopifyUser.fromJson(Map<String, dynamic> json) {
    return ShopifyUser(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      avatar: json['avatar'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      isEmailVerified:
          json['is_email_verified'] ?? json['email_verified'] ?? false,
      acceptsMarketing: json['accepts_marketing'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'accepts_marketing': acceptsMarketing,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return email;
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0].toUpperCase()}${lastName![0].toUpperCase()}';
    } else if (firstName != null) {
      return firstName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  ShopifyUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
    DateTime? dateOfBirth,
    bool? isEmailVerified,
    bool? acceptsMarketing,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ShopifyUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      acceptsMarketing: acceptsMarketing ?? this.acceptsMarketing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Custom Exception
class ShopifyAuthException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ShopifyAuthException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

// ==================== REPOSITORY EXAMPLE ==================== 
class ShopifyAuthRepository {
  final ShopifyAuthApiService _apiService = ShopifyAuthApiService();

  Future<ShopifyUser> login({
    required String email,
    required String password,
    bool rememberMe = false,
    String? deviceToken,
  }) async {
    final request = ShopifyLoginRequest(
      email: email,
      password: password,
      rememberMe: rememberMe,
      deviceToken: deviceToken,
    );

    final response = await _apiService.login(request);

    if (!response.success) {
      throw ShopifyAuthException(response.message, errors: response.errors);
    }

    return response.user!;
  }

  Future<ShopifyUser> signup({
    required String email,
    required String password,
    String? passwordConfirmation,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
    bool acceptsMarketing = false,
    String? deviceToken,
  }) async {
    final request = ShopifySignupRequest(
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dateOfBirth: dateOfBirth?.toIso8601String(),
      acceptsMarketing: acceptsMarketing,
      deviceToken: deviceToken,
    );

    final response = await _apiService.signup(request);

    if (!response.success) {
      throw ShopifyAuthException(response.message, errors: response.errors);
    }

    return response.user!;
  }

  Future<void> logout() async {
    await _apiService.logout();
  }

  Future<bool> forgotPassword(String email) async {
    return await _apiService.forgotPassword(email);
  }

  Future<ShopifyUser?> getCurrentUser() async {
    if (!_apiService.isLoggedIn) return null;

    try {
      return await _apiService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  bool get isLoggedIn => _apiService.isLoggedIn;

  String? get accessToken => _apiService.accessToken;
}
