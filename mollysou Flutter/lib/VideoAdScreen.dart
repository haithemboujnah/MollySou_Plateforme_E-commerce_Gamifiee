import 'package:flutter/material.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:mollysou/services/cooldown_service.dart';
import 'package:mollysou/services/user_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoAdScreen extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

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
            _showRewardDialog();
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

// Update the _saveWatchTime method in VideoAdScreen
  Future<void> _saveWatchTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastWatchTime', DateTime.now().millisecondsSinceEpoch);

    // Set cooldown to 3 hours
    final newCooldown = Duration(hours: 3);

    // Update cooldown in API if user is logged in
    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      final userId = userResult['userId'];
      try {
        await CooldownService.updateCooldown(userId, 'video');
        print('Video cooldown updated in API');
      } catch (e) {
        print('Error updating cooldown in API: $e');
        // Fallback to local storage
        await CooldownManager().saveLocalCooldown('Watch', newCooldown);
      }
    } else {
      await CooldownManager().saveLocalCooldown('Watch', newCooldown);
    }

    // Notify cooldown manager
    CooldownManager().updateVideoCooldown(newCooldown);
  }

  void _showRewardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.card_giftcard, color: Colors.green, size: 30),
              ),
              SizedBox(height: 16),
              Text(
                'Félicitations !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vous avez gagné'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFEAA7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration, color: Color(0xFF6A11CB)),
                    SizedBox(width: 8),
                    Text(
                      '100 points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A11CB),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Prochaine publicité disponible dans 3 heures',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Super !',
                style: TextStyle(
                  color: Color(0xFF6A11CB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
                'Vous pouvez regarder une publicité toutes les 3 heures pour gagner 100 points.',
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
                      'Regardez jusqu\'à la fin pour gagner 100 points',
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