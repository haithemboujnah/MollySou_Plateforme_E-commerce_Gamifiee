// lib/services/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CartService {
  static Future<List<dynamic>> getUserCart(int userId) async {
    try {
      final response = await ApiService.get('cart/$userId');

      if (response.statusCode == 200) {
        final List<dynamic> cartItems = json.decode(response.body);
        return cartItems;
      } else {
        throw Exception('Failed to load cart');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> addToCart(int userId, int productId, int quantity) async {
    try {
      final response = await ApiService.post('cart/$userId/add', {
        'productId': productId,
        'quantity': quantity,
      });

      if (response.statusCode == 200) {
        final cartItem = json.decode(response.body);
        return {'success': true, 'cartItem': cartItem};
      } else {
        return {'success': false, 'error': 'Failed to add to cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateCartItem(int userId, int productId, int quantity) async {
    try {
      final response = await ApiService.put('cart/$userId/update/$productId?quantity=$quantity', {});

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to update cart item'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(int userId, int productId) async {
    try {
      final response = await ApiService.delete('cart/$userId/remove/$productId');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to remove from cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> clearCart(int userId) async {
    try {
      final response = await ApiService.delete('cart/$userId/clear');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to clear cart'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<int> getCartItemCount(int userId) async {
    try {
      final response = await ApiService.get('cart/$userId/count');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }
}