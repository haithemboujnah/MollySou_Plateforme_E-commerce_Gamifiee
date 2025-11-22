import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'user_service.dart';

class PointsService {
  static Future<Map<String, dynamic>> addPoints(int userId, int points) async {
    try {
      final response = await ApiService.post('users/$userId/add-points', {
        'points': points,
      });

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Update local user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(userData));

        return {'success': true, 'user': userData};
      } else {
        return {'success': false, 'error': 'Failed to update points'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> addXP(int userId, int xp) async {
    try {
      final response = await ApiService.post('users/$userId/add-xp', {
        'xp': xp,
      });

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Update local user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(userData));

        return {'success': true, 'user': userData};
      } else {
        return {'success': false, 'error': 'Failed to update XP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePointsAndXP(int userId, int points, int xp) async {
    try {
      final response = await ApiService.post('users/$userId/update-points-xp', {
        'points': points,
        'xp': xp,
      });

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);

        // Update local user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(userData));

        return {'success': true, 'user': userData};
      } else {
        return {'success': false, 'error': 'Failed to update points and XP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}