import 'dart:convert';
import 'package:http/http.dart' as http;

class EventRecommendationService {
  static const String baseEventsUrl  = 'http://10.242.74.14:5002/api/events';

  static Future<Map<String, dynamic>> getRecommendedEvents(int? userId) async {
    try {
      final uri = Uri.parse('$baseEventsUrl/recommendations')
          .replace(queryParameters: {
        if (userId != null) 'user_id': userId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get recommended events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getPopularEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseEventsUrl/popular'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get popular events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> searchEvents(String query, {String? type, double? maxPrice}) async {
    try {
      final params = {'q': query};
      if (type != null) params['type'] = type;
      if (maxPrice != null) params['max_price'] = maxPrice.toString();

      final uri = Uri.parse('$baseEventsUrl/search').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search events');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getEventTypes() async {
    try {
      final response = await http.get(Uri.parse('$baseEventsUrl/types'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get event types');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getEventDetails(int eventId) async {
    try {
      final response = await http.get(Uri.parse('$baseEventsUrl/$eventId'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get event details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}