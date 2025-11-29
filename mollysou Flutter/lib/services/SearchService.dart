import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  static const String baseSearchUrl = 'http://10.242.74.14:5000/api';

  static Future<Map<String, dynamic>> searchCategories(String query, int? userId) async {
    try {
      final uri = Uri.parse('$baseSearchUrl/search/categories')
          .replace(queryParameters: {
        'q': query,
        if (userId != null) 'user_id': userId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search categories');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> searchProducts(String query, int? categoryId) async {
    try {
      final uri = Uri.parse('$baseSearchUrl/search/products')
          .replace(queryParameters: {
        'q': query,
        if (categoryId != null) 'category_id': categoryId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserRecommendations(int userId) async {
    try {
      final uri = Uri.parse('$baseSearchUrl/user/recommendations')
          .replace(queryParameters: {
        'user_id': userId.toString(),
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get user recommendations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}