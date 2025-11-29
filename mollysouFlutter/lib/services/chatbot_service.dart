// lib/services/chatbot_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String baseChatbotUrl = 'http://10.242.74.14:5001/api/chatbot';

  static Future<Map<String, dynamic>> sendMessage(String message, int? userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseChatbotUrl/message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'user_id': userId,
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  static Future<Map<String, dynamic>> getSuggestions(String query) async {
    try {
      final uri = Uri.parse('$baseChatbotUrl/suggestions')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      // Retourner des suggestions par défaut en cas d'erreur
      return {
        'suggestions': _getDefaultSuggestions(query),
        'type': 'default'
      };
    }
  }

  static List<String> _getDefaultSuggestions(String query) {
    if (query.isEmpty) {
      return [
        "Je cherche des produits pour",
        "Budget maximum",
        "Produits populaires en",
        "Cadeaux pour",
        "Promotions du moment"
      ];
    }

    final queryLower = query.toLowerCase();
    if (queryLower.contains('budget') || queryLower.contains('prix')) {
      return [
        "Budget maximum 50 DT",
        "Articles moins de 100 DT",
        "Produits premium 200+ DT"
      ];
    } else if (queryLower.contains('produit') || queryLower.contains('article')) {
      return [
        "Produits populaires",
        "Nouveautés à découvrir",
        "Meilleures ventes"
      ];
    } else {
      return [
        "Je cherche des $query",
        "Meilleurs $query",
        "$query pas cher"
      ];
    }
  }

  static Future<Map<String, dynamic>> getUserRecommendedProducts(int userId) async {
    try {
      final uri = Uri.parse('$baseChatbotUrl/user/products')
          .replace(queryParameters: {'user_id': userId.toString()});

      final response = await http.get(uri).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }
}