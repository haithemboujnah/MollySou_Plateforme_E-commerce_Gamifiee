import 'package:flutter/material.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:mollysou/services/cooldown_service.dart';
import 'package:mollysou/services/points_service.dart';
import 'package:mollysou/services/user_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoAdScreen extends StatefulWidget {
  final VoidCallback? onPointsEarned;

  const VideoAdScreen({Key? key, this.onPointsEarned}) : super(key: key);

  @override
  _VideoAdScreenState createState() => _VideoAdScreenState();
}

class _VideoAdScreenState extends State<VideoAdScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _videoCompleted = false;
  bool _canWatch = true;
  DateTime? _lastWatchTime;
  Duration _timeRemaining = Duration.zero;
  bool _showCooldownScreen = false;

  Map<String, dynamic> userData = {
    "level": 1,
    "points": 0,
    "xpActuel": 0,
    "xpProchainNiveau": 1000,
    "rank": "BRONZE",
    "nomComplet": "Utilisateur",
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      setState(() {
        final currentUser = userResult['user'];
        userData = {
          "level": currentUser?['niveau'] ?? 1,
          "points": currentUser?['points'] ?? 0,
          "xpActuel": currentUser?['xpActuel'] ?? 0,
          "xpProchainNiveau": currentUser?['xpProchainNiveau'] ?? 1000,
          "rank": currentUser?['rank'] ?? "BRONZE",
          "nomComplet": currentUser?['nomComplet'] ?? "Utilisateur",
        };
      });
    }

    // Charger le dernier temps de visionnage
    final lastWatchMillis = prefs.getInt('lastWatchTime');
    if (lastWatchMillis != null) {
      _lastWatchTime = DateTime.fromMillisecondsSinceEpoch(lastWatchMillis);
      _checkWatchAvailability();
    }

    // Si le cooldown est actif, montrer l'écran d'attente
    if (!_canWatch) {
      setState(() {
        _showCooldownScreen = true;
      });
    } else {
      // Sinon, initialiser la vidéo
      _initializeVideo();
    }

    _startTimer();
  }

  void _checkWatchAvailability() {
    if (_lastWatchTime != null) {
      final now = DateTime.now();
      final nextWatchTime = _lastWatchTime!.add(Duration(hours: 3));

      if (now.isBefore(nextWatchTime)) {
        setState(() {
          _canWatch = false;
          _timeRemaining = nextWatchTime.difference(now);
        });
      } else {
        setState(() {
          _canWatch = true;
          _timeRemaining = Duration.zero;
        });
      }
    }
  }

  void _startTimer() {
    // Mettre à jour le timer chaque seconde
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        _checkWatchAvailability();
        _startTimer();
      }
    });
  }

  Future<void> _initializeVideo() async {
    // Forcer l'orientation paysage seulement si on regarde la vidéo
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    try {
      _controller = VideoPlayerController.network(
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      );

      await _controller.initialize();

      // Lire automatiquement
      await _controller.play();

      // Écouter la fin de la vidéo
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration &&
            _controller.value.duration.inSeconds > 0) {
          if (!_videoCompleted) {
            setState(() {
              _videoCompleted = true;
            });
            _saveWatchTime();
          }
        }
      });

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Erreur vidéo: $e');
      _showErrorSnackbar('Erreur de chargement');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWatchTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastWatchTime', DateTime.now().millisecondsSinceEpoch);

    // Points et XP pour la vidéo
    int videoPoints = 300;

    // Mettre à jour les points et XP dans la base de données
    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      final userId = userResult['userId'];

      try {
        final pointsResult = await PointsService.addGameRewards(
          userId: userId,
          points: videoPoints,
          gameType: 'video',
        );

        if (pointsResult['success'] == true) {
          print('✅ Successfully added $videoPoints points and ${pointsResult['xpAdded']} XP from video ad');

          // FORCE REFRESH OF ALL USER DATA
          final refreshResult = await UserService.syncUserDataFromDatabase();

          if (refreshResult['success'] == true) {
            setState(() {
              final currentUser = refreshResult['user'];
              userData = {
                "level": currentUser?['niveau'] ?? 1,
                "points": currentUser?['points'] ?? 0,
                "xpActuel": currentUser?['xpActuel'] ?? 0,
                "xpProchainNiveau": currentUser?['xpProchainNiveau'] ?? 1000,
                "rank": currentUser?['rank'] ?? "BRONZE",
                "nomComplet": currentUser?['nomComplet'] ?? "Utilisateur",
              };
            });
            print('🔄 User data refreshed after video: Level ${userData["level"]}, Points ${userData["points"]}');
          }

          if (widget.onPointsEarned != null) {
            widget.onPointsEarned!();
          }

          // Check for level up
          final newUserData = pointsResult['user'];
          final oldLevel = userData['level'] ?? 1;
          final newLevel = newUserData['niveau'] ?? 1;

          if (newLevel > oldLevel) {
            _showLevelUpDialog(newLevel);
          } else {
            _showRewardSummary(videoPoints, pointsResult['xpAdded'] ?? 0);
          }
        } else {
          print('❌ Failed to update points: ${pointsResult['error']}');
          _showErrorSnackbar('Erreur lors de l\'ajout des points');
        }
      } catch (e) {
        print('❌ Error updating points: $e');
        _showErrorSnackbar('Erreur de connexion');
      }

      // Update cooldown
      try {
        await CooldownService.updateCooldown(userId, 'video');
        print('✅ Video cooldown updated in API');
      } catch (e) {
        print('❌ Error updating cooldown in API: $e');
        await CooldownManager().saveLocalCooldown('Watch', Duration(hours: 3));
      }
    } else {
      await CooldownManager().saveLocalCooldown('Watch', Duration(hours: 3));
    }

    // Notify cooldown manager
    CooldownManager().updateVideoCooldown(Duration(hours: 3));
  }

  void _showRewardSummary(int points, int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFF6A11CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.celebration, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Récompenses Gagnées !',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Points
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Color(0xFFFFEAA7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFD700)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
                  SizedBox(width: 8),
                  Text(
                    '$points Points',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // XP
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF4ECDC4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF4ECDC4)),
                  SizedBox(width: 8),
                  Text(
                    '$xp XP',
                    style: TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            Text(
              'Continuez à regarder des publicités pour gagner plus de récompenses !',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Super !',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Niveau Atteint !',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Félicitations !',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFD700)),
              ),
              child: Text(
                'Niveau $newLevel',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Continuez à jouer pour monter en rang !',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Super !',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String get _timeRemainingText {
    if (_timeRemaining.inSeconds <= 0) return '';

    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Restaurer l'orientation normale
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (!_showCooldownScreen) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _showCooldownScreen
          ? _buildCooldownScreen()
          : _buildVideoScreen(),
    );
  }

  Widget _buildCooldownScreen() {
    return Container(
      color: Color(0xFF1A1A2E),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône d'attente
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF6A11CB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: Color(0xFF6A11CB),
                  size: 50,
                ),
              ),
              SizedBox(height: 32),

              // Titre
              Text(
                'Publicité non disponible',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Description
              Text(
                'Vous pouvez regarder une publicité toutes les 3 heures pour gagner 300 points.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Timer
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF6A11CB)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Prochaine publicité dans',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _timeRemainingText,
                      style: TextStyle(
                        color: Color(0xFF6A11CB),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Bouton retour
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A11CB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'RETOUR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoScreen() {
    return _isLoading
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6A11CB)),
          SizedBox(height: 20),
          Text(
            'Chargement de la publicité...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    )
        : Stack(
      children: [
        // Vidéo en plein écran
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),

        // Overlay avec bouton fermer
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        // Indicateur de progression
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _controller.value.duration.inSeconds > 0
                      ? _controller.value.position.inSeconds / _controller.value.duration.inSeconds
                      : 0,
                  backgroundColor: Colors.grey[600],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Regardez jusqu\'à la fin pour gagner 300 points',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_controller.value.position.inMinutes}:${(_controller.value.position.inSeconds % 60).toString().padLeft(2, '0')} / '
                          '${_controller.value.duration.inMinutes}:${(_controller.value.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Message de complétion
        if (_videoCompleted)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'Publicité terminée !',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Retour automatique dans 3 secondes...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}