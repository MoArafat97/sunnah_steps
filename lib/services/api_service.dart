import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_service.dart';

class ApiService {
  static String get _baseUrl => dotenv.env['API_BASE_URL_LOCAL'] ?? dotenv.env['API_BASE_URL_PRODUCTION']!;
  
  /// Get authorization headers with Firebase token
  static Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Generic GET request
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  /// Generic POST request
  static Future<Map<String, dynamic>> _post(
    String endpoint, 
    Map<String, dynamic> body
  ) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: json.encode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data: ${response.statusCode}');
    }
  }

  // HABITS API
  
  /// Get all habits
  static Future<Map<String, dynamic>> getHabits({
    String? category,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    String endpoint = '/habits?limit=$limit&offset=$offset';
    if (category != null) endpoint += '&category=$category';
    if (tags != null && tags.isNotEmpty) {
      endpoint += '&tags=${tags.join(',')}';
    }
    return await _get(endpoint);
  }

  /// Get habit by ID
  static Future<Map<String, dynamic>> getHabit(String habitId) async {
    return await _get('/habits/$habitId');
  }

  /// Search habits
  static Future<Map<String, dynamic>> searchHabits(String query) async {
    return await _get('/habits/search/$query');
  }

  // BUNDLES API
  
  /// Get all bundles
  static Future<Map<String, dynamic>> getBundles({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _get('/bundles?limit=$limit&offset=$offset');
  }

  /// Get bundle by ID
  static Future<Map<String, dynamic>> getBundle(String bundleId) async {
    return await _get('/bundles/$bundleId');
  }

  /// Get habits in a bundle
  static Future<Map<String, dynamic>> getBundleHabits(String bundleId) async {
    return await _get('/bundles/$bundleId/habits');
  }

  // USERS API
  
  /// Create user profile
  static Future<Map<String, dynamic>> createUser({
    required String displayName,
    required String email,
    String role = 'user',
    String locale = 'en',
  }) async {
    return await _post('/users', {
      'displayName': displayName,
      'email': email,
      'role': role,
      'locale': locale,
    });
  }

  /// Get user profile
  static Future<Map<String, dynamic>> getUser(String userId) async {
    return await _get('/users/$userId');
  }

  // COMPLETIONS API
  
  /// Log habit completion
  static Future<Map<String, dynamic>> createCompletion({
    required String habitId,
    String source = 'api',
    String? note,
  }) async {
    return await _post('/completions', {
      'habitId': habitId,
      'source': source,
      if (note != null) 'note': note,
    });
  }

  /// Get user's completion history
  static Future<Map<String, dynamic>> getCompletions(
    String userId, {
    String? habitId,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    String endpoint = '/completions/$userId?limit=$limit&offset=$offset';
    if (habitId != null) endpoint += '&habitId=$habitId';
    if (startDate != null) endpoint += '&startDate=$startDate';
    if (endDate != null) endpoint += '&endDate=$endDate';
    return await _get(endpoint);
  }

  /// Get completion statistics
  static Future<Map<String, dynamic>> getCompletionStats(
    String userId, {
    int days = 30,
  }) async {
    return await _get('/completions/$userId/stats?days=$days');
  }
}
