// lib/services/points_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mollysou/services/user_service.dart';
import 'api_service.dart';

class PointsService {
  static Future<Map<String, dynamic>> addPoints(int userId, int points) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/$userId/add-points'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'points': points,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'user': result,
          'pointsAdded': points,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to add points: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addXP(int userId, int xp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/$userId/add-xp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'xp': xp,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return {
          'success': true,
          'user': result,
          'xpAdded': xp,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to add XP: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> addPointsAndXP(int userId, int points, int xp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/$userId/update-points-xp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'points': points,
          'xp': xp,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // UPDATE LOCAL STORAGE IMMEDIATELY
        await UserService.updateLocalUserData(result);

        // Also force a full sync from database to ensure consistency
        await UserService.syncUserDataFromDatabase();

        print('✅ Points and XP updated in database and local storage');

        return {
          'success': true,
          'user': result,
          'pointsAdded': points,
          'xpAdded': xp,
        };
      } else {
        print('❌ API error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to add points and XP: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Network error in addPointsAndXP: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }


  // Méthode spécifique pour les jeux avec bonus XP automatique
  static Future<Map<String, dynamic>> addGameRewards({
    required int userId,
    required int points,
    required String gameType,
    int? bonusXP,
  }) async {
    try {
      // Calculer l'XP total (points + bonus selon le jeu)
      int xpBonus = bonusXP ?? _getGameXPBonus(gameType);
      int totalXP = points + xpBonus;

      print('🎮 Adding game rewards - User: $userId, Points: $points, XP: $totalXP, Game: $gameType');

      // Use the combined method to add both points and XP
      final result = await addPointsAndXP(userId, points, totalXP);

      if (result['success'] == true && result['user'] != null) {
        final updatedUser = result['user'];
        print('✅ Game rewards added successfully - New Level: ${updatedUser['niveau']}, New Points: ${updatedUser['points']}');

        // Force immediate sync to ensure all screens have updated data
        await UserService.syncUserDataFromDatabase();

        return {
          'success': true,
          'user': updatedUser,
          'pointsAdded': points,
          'xpAdded': totalXP,
        };
      } else {
        print('❌ Failed to add game rewards: ${result['error']}');
        return result;
      }
    } catch (e) {
      print('❌ Error in addGameRewards: $e');
      return {
        'success': false,
        'error': 'Game rewards error: $e',
      };
    }
  }

  static int _getGameXPBonus(String gameType) {
    switch (gameType) {
      case 'wheel':
        return 25; // Bonus XP pour la roue
      case 'puzzle':
        return 50; // Bonus XP pour le puzzle (plus stratégique)
      case 'video':
        return 10; // Bonus XP pour les vidéos
      default:
        return 0;
    }
  }

  static Future<Map<String, dynamic>> addPurchaseRewards({
    required int userId,
    required double purchaseAmount,
    required int basePoints,
  }) async {
    try {
      // Calculer les points basés sur le montant d'achat (1 point par DT)
      int purchasePoints = purchaseAmount.toInt();
      int totalPoints = basePoints + purchasePoints;

      // Bonus XP pour les achats (2 XP par DT dépensé)
      int purchaseXP = (purchaseAmount * 2).toInt();

      print('Adding purchase rewards - Amount: $purchaseAmount DT, Points: $totalPoints, XP: $purchaseXP');

      final result = await addPointsAndXP(userId, totalPoints, purchaseXP);

      // SYNC LOCAL STORAGE IMMEDIATELY AFTER SUCCESS
      if (result['success'] == true && result['user'] != null) {
        await UserService.updateLocalUserData(result['user']);
        await UserService.syncUserDataFromDatabase();
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Purchase rewards error: $e',
      };
    }
  }

  // Méthode spécifique pour les achats avec calcul automatique
  static Future<Map<String, dynamic>> addPurchaseXP({
    required int userId,
    required double purchaseAmount,
  }) async {
    // Points de base pour tout achat
    int basePoints = 50;

    return await addPurchaseRewards(
      userId: userId,
      purchaseAmount: purchaseAmount,
      basePoints: basePoints,
    );
  }

}


