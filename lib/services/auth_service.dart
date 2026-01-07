import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.login)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'] ?? data['access_token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Log masuk gagal. Sila cuba lagi.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ralat berlaku. Sila semak sambungan internet anda.',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String googleId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.loginGoogle)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'google_id': googleId,
          'email': email,
          'name': name,
          'photo_url': photoUrl,
        }),
      );

      // Check if response body is empty or not valid JSON
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Tiada respons dari pelayan. Sila cuba lagi.',
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Respons tidak sah dari pelayan: ${response.body}',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'] ?? data['access_token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Log masuk Google gagal. Kod: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ralat berlaku semasa log masuk dengan Google: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.register)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'token': data['token'] ?? data['access_token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Pendaftaran gagal. Sila cuba lagi.',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ralat berlaku. Sila semak sambungan internet anda.',
      };
    }
  }

  Future<bool> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.logout)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getUrl(ApiConfig.forgotPassword)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pautan reset kata laluan telah dihantar ke alamat emel anda.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Ralat berlaku. Sila cuba lagi.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Ralat berlaku. Sila semak sambungan internet anda.',
      };
    }
  }
}

