import 'package:flutter/material.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:mollysou/services/points_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'services/user_service.dart';
import 'services/cooldown_service.dart';

class ReflexGameScreen extends StatefulWidget {
  final VoidCallback? onPointsEarned;

  const ReflexGameScreen({Key? key, this.onPointsEarned}) : super(key: key);

  @override
  _ReflexGameScreenState createState() => _ReflexGameScreenState();
}

class _ReflexGameScreenState extends State<ReflexGameScreen> {
  // État du jeu
  GameState _gameState = GameState.waiting;
  int _score = 0;
  int _timeLeft = 30; // 30 secondes de jeu
  int _targetsHit = 0;
  double _targetX = 0.0;
  double _targetY = 0.0;
  bool _targetVisible = false;
  int _targetLifetime = 2000; // 2 secondes par défaut
  int _reactionTime = 0;
  DateTime? _targetAppearTime;

  // Gestion du temps
  late Timer _gameTimer;
  late Timer _targetTimer;

  // Cooldown et utilisateur
  bool _isDarkMode = false;
  bool _canPlay = true;
  Duration _timeRemaining = Duration.zero;
  int? _userId;

  Map<String, dynamic> userData = {
    "level": 1,
    "points": 0,
    "xpActuel": 0,
    "xpProchainNiveau": 1000,
    "rank": "BRONZE",
    "nomComplet": "Utilisateur",
  };

  // Couleurs des cibles
  final List<Color> _targetColors = [
    Color(0xFFFF6B6B), // Rouge
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFF45B7D1), // Bleu
    Color(0xFF96CEB4), // Vert
    Color(0xFFFFEAA7), // Jaune
    Color(0xFFDDA0DD), // Violet
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAndPreferences();
  }

  Future<void> _loadUserAndPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });

    // Get user ID and user data
    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      setState(() {
        _userId = userResult['userId'];
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
      await _loadCooldownsFromApi();
    }
  }

  Future<void> _loadCooldownsFromApi() async {
    if (_userId == null) {
      await _loadLocalCooldowns();
      return;
    }

    try {
      final cooldowns = await CooldownService.getUserCooldowns(_userId!);
      final reflexCooldownSeconds = cooldowns['reflexCooldown'] ?? 0;
      setState(() {
        _timeRemaining = Duration(seconds: reflexCooldownSeconds);
        _canPlay = reflexCooldownSeconds <= 0;
      });

      if (reflexCooldownSeconds > 0) {
        _startCooldownTimer();
      }
    } catch (e) {
      print('Error loading cooldowns from API: $e');
      await _loadLocalCooldowns();
    }
  }

  Future<void> _loadLocalCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGameMillis = prefs.getInt('lastReflexGameTime');
    if (lastGameMillis != null) {
      final lastGameTime = DateTime.fromMillisecondsSinceEpoch(lastGameMillis);
      final nextGameTime = lastGameTime.add(Duration(hours: 1));
      final now = DateTime.now();

      if (now.isBefore(nextGameTime)) {
        setState(() {
          _timeRemaining = nextGameTime.difference(now);
          _canPlay = false;
        });
        _startCooldownTimer();
      } else {
        setState(() {
          _canPlay = true;
          _timeRemaining = Duration.zero;
        });
      }
    }
  }

  void _startCooldownTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_timeRemaining.inSeconds > 0) {
            _timeRemaining = _timeRemaining - Duration(seconds: 1);
          } else {
            _canPlay = true;
          }
        });

        if (_timeRemaining.inSeconds > 0) {
          _startCooldownTimer();
        }
      }
    });
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _appBarColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _iconColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);

  String get _timeRemainingText {
    if (_timeRemaining.inSeconds <= 0) return '';
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _startGame() {
    if (!_canPlay) return;

    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _timeLeft = 30;
      _targetsHit = 0;
      _targetLifetime = 2000;
    });

    _startGameTimer();
    _spawnTarget();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft--;
        });

        if (_timeLeft <= 0) {
          _endGame();
          timer.cancel();
        }
      }
    });
  }

  void _spawnTarget() {
    if (_gameState != GameState.playing) return;

    final random = DateTime.now().millisecondsSinceEpoch;
    final colorIndex = random % _targetColors.length;

    setState(() {
      _targetX = (random % 700 + 50).toDouble(); // Position X aléatoire
      _targetY = (random % 500 + 100).toDouble(); // Position Y aléatoire
      _targetVisible = true;
      _targetAppearTime = DateTime.now();

      // Réduire le temps d'apparition progressivement
      _targetLifetime = (_targetLifetime * 0.9).clamp(800, 2000).toInt();
    });

    _targetTimer = Timer(Duration(milliseconds: _targetLifetime), () {
      if (_targetVisible && _gameState == GameState.playing) {
        setState(() {
          _targetVisible = false;
        });
        _spawnTarget();
      }
    });
  }

  void _hitTarget() {
    if (!_targetVisible || _gameState != GameState.playing) return;

    final now = DateTime.now();
    final reactionTime = now.difference(_targetAppearTime!).inMilliseconds;

    // Calcul des points : plus la réaction est rapide, plus on gagne de points
    int points = 0;
    if (reactionTime < 500) {
      points = 15; // Réaction très rapide
    } else if (reactionTime < 1000) {
      points = 10; // Réaction rapide
    } else {
      points = 5; // Réaction normale
    }

    // Bonus pour les cibles consécutives
    if (_targetsHit > 0 && _targetsHit % 5 == 0) {
      points += 10; // Bonus tous les 5 coups
    }

    setState(() {
      _score += points;
      _targetsHit++;
      _targetVisible = false;
      _reactionTime = reactionTime;
    });

    // Annuler le timer actuel et faire apparaître une nouvelle cible
    _targetTimer.cancel();
    _spawnTarget();
  }

  void _endGame() {
    _gameTimer.cancel();
    if (_targetTimer.isActive) {
      _targetTimer.cancel();
    }

    setState(() {
      _gameState = GameState.finished;
      _targetVisible = false;
    });

    _updatePointsInDatabase();
    _updateCooldown();
  }

  Future<void> _updatePointsInDatabase() async {
    if (_userId != null) {
      try {
        final result = await PointsService.addGameRewards(
          userId: _userId!,
          points: _score,
          gameType: 'reflex',
        );

        if (result['success'] == true) {
          print('✅ Successfully added $_score points from reflex game');

          // Refresh user data
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
          }

          if (widget.onPointsEarned != null) {
            widget.onPointsEarned!();
          }

          // Check for level up
          final newUserData = result['user'];
          final oldLevel = userData['level'] ?? 1;
          final newLevel = newUserData['niveau'] ?? 1;

          if (newLevel > oldLevel) {
            _showLevelUpDialog(newLevel);
          } else {
            _showGameSummary();
          }
        }
      } catch (e) {
        print('❌ Error updating points: $e');
      }
    }
  }

  void _showGameSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
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
              child: Icon(Icons.bolt, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Score Final !',
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score
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
                    '$_score Points',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Statistiques
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF4ECDC4)),
              ),
              child: Column(
                children: [
                  Text(
                    'Cibles touchées: $_targetsHit',
                    style: TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Temps de réaction moyen: ${_targetsHit > 0 ? (_reactionTime ~/ _targetsHit) : 0}ms',
                    style: TextStyle(
                      color: Color(0xFF4ECDC4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),
            Text(
              'Vos réflexes sont excellents !',
              style: TextStyle(
                color: _secondaryTextColor,
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
        backgroundColor: _cardColor,
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
                color: _textColor,
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
                color: _secondaryTextColor,
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
              'Vos réflexes vous ont fait monter en niveau !',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog de niveau
              _showGameSummary(); // Montrer le résumé du jeu
            },
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

  Future<void> _updateCooldown() async {
    final newCooldown = Duration(hours: 1);

    if (_userId != null) {
      try {
        await CooldownService.updateCooldown(_userId!, 'reflex');
        print('Reflex cooldown updated in API');
      } catch (e) {
        print('Error updating cooldown in API: $e');
        await CooldownManager().saveLocalCooldown('Reflex', newCooldown);
      }
    } else {
      await CooldownManager().saveLocalCooldown('Reflex', newCooldown);
    }

    CooldownManager().updateReflexCooldown(newCooldown);

    setState(() {
      _timeRemaining = newCooldown;
      _canPlay = false;
    });
    _startCooldownTimer();
  }

  @override
  void dispose() {
    if (_gameTimer.isActive) _gameTimer.cancel();
    if (_targetTimer.isActive) _targetTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Course de Réflexes ⚡', style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête avec cooldown
            if (!_canPlay && _gameState == GameState.waiting)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Color(0xFF0F3460) : Colors.orange[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, size: 20,
                        color: _isDarkMode ? Colors.orange[200] : Colors.orange[600]),
                    SizedBox(width: 8),
                    Text(
                      'Prochaine partie: $_timeRemainingText',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.orange[200] : Colors.orange[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Statistiques du jeu
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(_isDarkMode ? 0.3 : 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Timer du jeu
                  if (_gameState == GameState.playing)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 10 ? Colors.red.withOpacity(0.2) :
                        _isDarkMode ? Color(0xFF0F3460) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _timeLeft <= 10 ? Colors.red :
                          _isDarkMode ? Colors.blue : Colors.blue,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 16,
                              color: _timeLeft <= 10 ? Colors.red :
                              _isDarkMode ? Colors.blue[200] : Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            '$_timeLeft secondes',
                            style: TextStyle(
                              color: _timeLeft <= 10 ? Colors.red :
                              _isDarkMode ? Colors.blue[200] : Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Score', '$_score', Icons.celebration, Color(0xFFFF6B6B)),
                      _buildStat('Cibles', '$_targetsHit', Icons.radio_button_checked, Color(0xFF4ECDC4)),
                      _buildStat('Temps', '$_timeLeft', Icons.timer, Color(0xFF45B7D1)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Zone de jeu
            Expanded(
              child: Stack(
                children: [
                  // Zone de jeu principale
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDarkMode ? Color(0xFF1E3A8A) : Colors.grey[300]!,
                      ),
                    ),
                    child: _gameState == GameState.waiting
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bolt, size: 60, color: _secondaryTextColor),
                          SizedBox(height: 16),
                          Text(
                            'Course de Réflexes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Touchez les cibles le plus vite possible !\n30 secondes pour marquer un maximum de points.',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          if (_targetsHit > 0)
                            Text(
                              'Record: $_score points',
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    )
                        : _gameState == GameState.finished
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.celebration, size: 60, color: Color(0xFFFFD700)),
                          SizedBox(height: 16),
                          Text(
                            'Partie Terminée !',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Score final: $_score points',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cibles touchées: $_targetsHit',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : Container(), // Zone de jeu vide pendant la partie
                  ),

                  // Cible
                  if (_targetVisible && _gameState == GameState.playing)
                    Positioned(
                      left: _targetX,
                      top: _targetY,
                      child: GestureDetector(
                        onTap: _hitTarget,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _targetColors[_targetsHit % _targetColors.length],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _targetColors[_targetsHit % _targetColors.length].withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                  // Instructions pendant le jeu
                  if (_gameState == GameState.playing && !_targetVisible)
                    Center(
                      child: Text(
                        'Préparez-vous...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Boutons d'action
            if (_gameState != GameState.playing)
              Container(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _canPlay ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canPlay ? Color(0xFF6A11CB) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: _canPlay ? 5 : 0,
                  ),
                  child: !_canPlay
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'PROCHAINE PARTIE: $_timeRemainingText',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    _gameState == GameState.finished ? 'REJOUER' : 'COMMENCER LA PARTIE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: _endGame,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'ARRÊTER LA PARTIE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

enum GameState {
  waiting,
  playing,
  finished,
}