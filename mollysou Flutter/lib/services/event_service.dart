import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class EventService {
  static Future<List<dynamic>> getAllEvents() async {
    try {
      final response = await ApiService.get('events');

      if (response.statusCode == 200) {
        final List<dynamic> events = json.decode(response.body);
        return events;
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> getPopularEvents() async {
    try {
      final response = await ApiService.get('events/popular');

      if (response.statusCode == 200) {
        final List<dynamic> events = json.decode(response.body);
        return events;
      } else {
        throw Exception('Failed to load popular events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getEventById(int id) async {
    try {
      final response = await ApiService.get('events/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> event = json.decode(response.body);
        return event;
      } else {
        throw Exception('Failed to load event');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}