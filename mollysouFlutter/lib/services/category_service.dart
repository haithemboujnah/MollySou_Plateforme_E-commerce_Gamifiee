import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CategoryService {
  static Future<List<dynamic>> getAllCategories() async {
    try {
      final response = await ApiService.get('categories');

      if (response.statusCode == 200) {
        final List<dynamic> categories = json.decode(response.body);
        return categories;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCategoryById(int id) async {
    try {
      final response = await ApiService.get('categories/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> category = json.decode(response.body);
        return category;
      } else {
        throw Exception('Failed to load category');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}