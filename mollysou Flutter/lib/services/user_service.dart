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

  static Future<void> updateLocalUserData(Map<String, dynamic> newUserData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get current user data from local storage - USE CORRECT KEY
      final userJson = prefs.getString('user'); // Changed from 'flutter.user' to 'user'
      if (userJson != null) {
        Map<String, dynamic> userData = json.decode(userJson);

        // Update only the fields that change
        userData['niveau'] = newUserData['niveau'] ?? userData['niveau'];
        userData['points'] = newUserData['points'] ?? userData['points'];
        userData['xpActuel'] = newUserData['xpActuel'] ?? userData['xpActuel'];
        userData['xpProchainNiveau'] = newUserData['xpProchainNiveau'] ?? userData['xpProchainNiveau'];
        userData['rank'] = newUserData['rank'] ?? userData['rank'];

        // Save updated user data back to local storage - USE CORRECT KEY
        await prefs.setString('user', json.encode(userData)); // Changed from 'flutter.user' to 'user'
        print('✅ Local user data updated successfully - Level: ${userData['niveau']}, Points: ${userData['points']}');
      } else {
        print('❌ No user data found in local storage');
      }
    } catch (e) {
      print('❌ Error updating local user data: $e');
    }
  }

  static Future<Map<String, dynamic>> syncUserDataFromDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      // Fetch fresh data from API
      final response = await ApiService.get('users/$userId');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Update local storage with fresh data - USE CORRECT KEY
        await prefs.setString('user', json.encode(userData)); // This is the correct key
        await prefs.setInt('userId', userData['id']);

        print('✅ User data synced from database: Level ${userData['niveau']}, Points ${userData['points']}');

        return {'success': true, 'user': userData};
      } else {
        print('❌ Failed to sync user data: ${response.statusCode}');
        return {'success': false, 'error': 'Failed to sync user data'};
      }
    } catch (e) {
      print('❌ Error syncing user data: $e');
      return {'success': false, 'error': 'Sync error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user'); // This is the correct key
      final userId = prefs.getInt('userId');

      if (userString != null && userId != null) {
        final userData = json.decode(userString);
        print('📱 Loaded user from local storage - Level: ${userData['niveau']}, Points: ${userData['points']}');

        return {
          'success': true,
          'user': userData,
          'userId': userId
        };
      } else {
        print('❌ No user data in local storage');
        return {'success': false, 'error': 'Utilisateur non connecté'};
      }
    } catch (e) {
      print('❌ Error getting current user: $e');
      return {'success': false, 'error': 'Error getting user: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshUserData() async {
    return await syncUserDataFromDatabase();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('lastSpinTime');
    await prefs.remove('lastGameTime');
    await prefs.remove('lastWatchTime');
    await prefs.remove('lastReflexTime');
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}