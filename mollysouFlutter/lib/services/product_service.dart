import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ProductService {
  static Future<List<dynamic>> getProductsByCategory(int categoryId) async {
    try {
      final response = await ApiService.get('products/category/$categoryId');

      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);
        return products;
      } else {
        throw Exception('Failed to load products for category $categoryId');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> getAvailableProducts() async {
    try {
      final response = await ApiService.get('products/available');

      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);
        return products;
      } else {
        throw Exception('Failed to load available products');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> getProductById(int id) async {
    try {
      final response = await ApiService.get('products/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> product = json.decode(response.body);
        return product;
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}