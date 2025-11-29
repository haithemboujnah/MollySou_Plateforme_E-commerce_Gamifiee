// lib/services/cooldown_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CooldownService {
  static Future<Map<String, dynamic>> getUserCooldowns(int userId) async {
    try {
      final response = await ApiService.get('users/$userId/cooldowns');

      if (response.statusCode == 200) {
        final Map<String, dynamic> cooldowns = json.decode(response.body);
        print('Cooldowns from API: $cooldowns'); // Debug log
        return cooldowns;
      } else {
        throw Exception('Failed to load cooldowns: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading cooldowns: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<void> updateCooldown(int userId, String type) async {
    try {
      final response = await ApiService.post('users/$userId/cooldown/$type', {});

      if (response.statusCode != 200) {
        throw Exception('Failed to update cooldown: ${response.statusCode}');
      }
      print('Cooldown updated successfully for type: $type'); // Debug log
    } catch (e) {
      print('Error updating cooldown: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserRankInfo(int userId, int level) async {
    try {
      final response = await ApiService.get('users/$userId/rank-info?level=$level');

      if (response.statusCode == 200) {
        final Map<String, dynamic> rankInfo = json.decode(response.body);
        return rankInfo;
      } else {
        throw Exception('Failed to load rank info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading rank info: $e');
      throw Exception('Network error: $e');
    }
  }
}