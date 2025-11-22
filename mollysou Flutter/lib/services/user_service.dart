// lib/services/user_service.dart (updated)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('users/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);

      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData));
      await prefs.setString('token', 'logged_in');
      await prefs.setInt('userId', userData['id']);

      return {'success': true, 'user': userData};
    } else if (response.statusCode == 401) {
      return {'success': false, 'error': 'Email ou mot de passe incorrect'};
    } else {
      return {'success': false, 'error': 'Erreur de connexion'};
    }
  }

  static Future<Map<String, dynamic>> register(
      String email,
      String password,
      String nomComplet,
      String genre
      ) async {
    final response = await ApiService.post('users/register', {
      'email': email,
      'password': password,
      'nomComplet': nomComplet,
      'genre': genre,
    });

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);

      // Save user data to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData));
      await prefs.setString('token', 'logged_in');
      await prefs.setInt('userId', userData['id']); // Save user ID

      return {'success': true, 'user': userData};
    } else if (response.statusCode == 400) {
      return {'success': false, 'error': 'Email déjà utilisé'};
    } else {
      return {'success': false, 'error': 'Erreur lors de l\'inscription'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    final userId = prefs.getInt('userId');

    if (userString != null && userId != null) {
      return {
        'success': true,
        'user': json.decode(userString),
        'userId': userId
      };
    } else {
      return {'success': false, 'error': 'Utilisateur non connecté'};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('lastSpinTime');
    await prefs.remove('lastGameTime');
    await prefs.remove('lastWatchTime');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}