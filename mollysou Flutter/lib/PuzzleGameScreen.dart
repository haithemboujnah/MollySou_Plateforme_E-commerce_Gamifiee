import 'package:flutter/material.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'services/user_service.dart';
import 'services/cooldown_service.dart';

class PuzzleGameScreen extends StatefulWidget {
  @override
  _PuzzleGameScreenState createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  List<MemoryCard> _cards = [];
  MemoryCard? _firstCard;
  MemoryCard? _secondCard;
  bool _canFlip = true;
  int _matchesFound = 0;
  int _totalPairs = 8;
  int _moves = 0;
  int _points = 0;
  bool _gameCompleted = false;
  bool _isDarkMode = false;
  bool _hintUsed = false;
  bool _canPlay = true;
  Duration _timeRemaining = Duration.zero;
  int _timeLeft = 60; // 1 minute timer
  late Timer _gameTimer;
  bool _gameStarted = false;
  int? _userId;

  final List<String> _emojis = [
    '🔥', '🔥',
    '💎', '💎',
    '🎯', '🎯',
    '🚀', '🚀',
    '🌈', '🌈',
    '🧩', '🧩',
    '🎉', '🎉',
    '💰', '💰',
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

    // Get user ID
    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      setState(() {
        _userId = userResult['userId'];
      });
      await _loadCooldownsFromApi();
    } else {
      // Fallback to local storage if no user
      await _loadLocalCooldowns();
    }
  }

  Future<void> _loadCooldownsFromApi() async {
    if (_userId == null) {
      await _loadLocalCooldowns();
      return;
    }

    try {
      final cooldowns = await CooldownService.getUserCooldowns(_userId!);

      final puzzleCooldownSeconds = cooldowns['puzzleCooldown'] ?? 0;
      setState(() {
        _timeRemaining = Duration(seconds: puzzleCooldownSeconds);
        _canPlay = puzzleCooldownSeconds <= 0;
      });

      if (puzzleCooldownSeconds > 0) {
        _startCooldownTimer();
      }
    } catch (e) {
      print('Error loading cooldowns from API: $e');
      // Fallback to local storage
      await _loadLocalCooldowns();
    }
  }

  Future<void> _loadLocalCooldowns() async {
    final prefs = await SharedPreferences.getInstance();

    final lastGameMillis = prefs.getInt('lastGameTime');
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

  void _startGameTimer() {
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft--;
        });

        if (_timeLeft <= 0) {
          _endGameByTime();
          timer.cancel();
        }
      }
    });
  }

  void _endGameByTime() {
    _gameTimer.cancel();
    setState(() {
      _gameCompleted = true;
      _canFlip = false;
    });

    _updateCooldown();
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

  void _initializeGame() {
    if (!_canPlay) return;

    setState(() {
      // Mélanger les cartes
      List<String> shuffledEmojis = List.from(_emojis)..shuffle();

      _cards = List.generate(16, (index) {
        return MemoryCard(
          id: index,
          emoji: shuffledEmojis[index],
          isFlipped: false,
          isMatched: false,
        );
      });

      _firstCard = null;
      _secondCard = null;
      _canFlip = true;
      _matchesFound = 0;
      _moves = 0;
      _points = 0;
      _gameCompleted = false;
      _hintUsed = false;
      _timeLeft = 60;
      _gameStarted = true;
    });

    _startGameTimer();
  }

  void _flipCard(int index) {
    if (!_canFlip || !_gameStarted ||
        _cards[index].isFlipped ||
        _cards[index].isMatched ||
        _gameCompleted) {
      return;
    }

    setState(() {
      _cards[index] = _cards[index].copyWith(isFlipped: true);

      if (_firstCard == null) {
        _firstCard = _cards[index];
      } else {
        _secondCard = _cards[index];
        _canFlip = false;
        _moves++;
        _checkForMatch();
      }
    });
  }

  void _checkForMatch() {
    if (_firstCard != null && _secondCard != null) {
      if (_firstCard!.emoji == _secondCard!.emoji) {
        // Match trouvé !
        setState(() {
          _cards[_firstCard!.id] = _firstCard!.copyWith(isMatched: true);
          _cards[_secondCard!.id] = _secondCard!.copyWith(isMatched: true);
          _matchesFound++;
          _points += 50; // 50 points par paire trouvée
        });

        if (_matchesFound == _totalPairs) {
          _completeGame();
        }

        _resetSelection();
      } else {
        // Pas de match, retourner les cartes après un délai
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _cards[_firstCard!.id] = _firstCard!.copyWith(isFlipped: false);
              _cards[_secondCard!.id] = _secondCard!.copyWith(isFlipped: false);
              _resetSelection();
            });
          }
        });
      }
    }
  }

  void _resetSelection() {
    setState(() {
      _firstCard = null;
      _secondCard = null;
      _canFlip = true;
    });
  }

  void _completeGame() {
    _gameTimer.cancel();
    setState(() {
      _gameCompleted = true;
      _points += 200; // Bonus de complétion
    });

    _updateCooldown();
  }

  Future<void> _updateCooldown() async {
    // Set cooldown to 1 hour
    final newCooldown = Duration(hours: 1);

    print('Setting puzzle cooldown to: $newCooldown');

    // Update cooldown in API
    if (_userId != null) {
      try {
        await CooldownService.updateCooldown(_userId!, 'puzzle');
        print('Puzzle cooldown updated in API');
      } catch (e) {
        print('Error updating cooldown in API: $e');
        // Fallback to local storage
        await CooldownManager().saveLocalCooldown('Game', newCooldown);
      }
    } else {
      await CooldownManager().saveLocalCooldown('Game', newCooldown);
    }

    // Notify cooldown manager - THIS IS THE KEY FIX
    CooldownManager().updatePuzzleCooldown(newCooldown);

    setState(() {
      _timeRemaining = newCooldown;
      _canPlay = false;
    });
    _startCooldownTimer();
  }

  Future<void> _saveLastGameTimeLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastGameTime', DateTime.now().millisecondsSinceEpoch);
    print('Puzzle cooldown saved locally');
  }

  void _hint() {
    if (_hintUsed || !_gameStarted || _gameCompleted) return;

    // Trouver une paire non découverte
    var unmatchedCards = _cards.where((card) => !card.isMatched && !card.isFlipped).toList();
    if (unmatchedCards.length >= 2) {
      // Trouver une paire
      for (int i = 0; i < unmatchedCards.length; i++) {
        for (int j = i + 1; j < unmatchedCards.length; j++) {
          if (unmatchedCards[i].emoji == unmatchedCards[j].emoji) {
            setState(() {
              _hintUsed = true;
            });

            // Montrer brièvement la paire
            setState(() {
              _cards[unmatchedCards[i].id] = unmatchedCards[i].copyWith(isFlipped: true);
              _cards[unmatchedCards[j].id] = unmatchedCards[j].copyWith(isFlipped: true);
            });

            Future.delayed(Duration(milliseconds: 1500), () {
              if (mounted && !_cards[unmatchedCards[i].id].isMatched) {
                setState(() {
                  _cards[unmatchedCards[i].id] = unmatchedCards[i].copyWith(isFlipped: false);
                  _cards[unmatchedCards[j].id] = unmatchedCards[j].copyWith(isFlipped: false);
                });
              }
            });
            return;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    if (_gameStarted) {
      _gameTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Jeu de Mémoire', style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_gameStarted && !_gameCompleted)
            IconButton(
              icon: Icon(
                  Icons.lightbulb_outline,
                  color: _hintUsed ? Colors.grey : Color(0xFFFF6B6B)
              ),
              onPressed: _hintUsed ? null : _hint,
              tooltip: _hintUsed ? 'Indice déjà utilisé' : 'Indice (1 seule fois)',
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête avec timer de cooldown
            if (!_canPlay && !_gameStarted)
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
                  if (_gameStarted && !_gameCompleted)
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
                      _buildStat('Points', '$_points', Icons.celebration, Color(0xFFFF6B6B)),
                      _buildStat('Paires', '$_matchesFound/$_totalPairs', Icons.checklist, Color(0xFF4ECDC4)),
                      _buildStat('Mouvements', '$_moves', Icons.swap_horiz, Color(0xFF45B7D1)),
                    ],
                  ),

                  // Indice utilisé
                  if (_hintUsed)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Indice utilisé ✓',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Grille de mémoire 4x4
            Expanded(
              child: _gameStarted
                  ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: 16,
                itemBuilder: (context, index) {
                  return _buildMemoryCard(_cards[index]);
                },
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.memory, size: 60, color: _secondaryTextColor),
                    SizedBox(height: 16),
                    Text(
                      'Jeu de Mémoire',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Trouvez toutes les paires en 1 minute !',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Message de victoire ou défaite
            if (_gameCompleted)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _matchesFound == _totalPairs
                      ? (_isDarkMode ? Colors.green[900]! : Colors.green[50])
                      : (_isDarkMode ? Colors.orange[900]! : Colors.orange[50]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _matchesFound == _totalPairs ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _matchesFound == _totalPairs ? Icons.celebration : Icons.timer_off,
                      size: 50,
                      color: _matchesFound == _totalPairs ? Colors.green : Colors.orange,
                    ),
                    SizedBox(height: 10),
                    Text(
                      _matchesFound == _totalPairs
                          ? 'Bravo ! Mémoire Parfaite 🎉'
                          : 'Temps écoulé !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _matchesFound == _totalPairs
                            ? (_isDarkMode ? Colors.green[100] : Colors.green[800])
                            : (_isDarkMode ? Colors.orange[100] : Colors.orange[800]),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _matchesFound == _totalPairs
                          ? 'Vous avez gagné $_points points !'
                          : 'Vous avez gagné $_points points',
                      style: TextStyle(
                        color: _matchesFound == _totalPairs
                            ? (_isDarkMode ? Colors.green[200] : Colors.green[700])
                            : (_isDarkMode ? Colors.orange[200] : Colors.orange[700]),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Boutons d'action
            if (!_gameStarted || _gameCompleted)
              Container(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _canPlay ? _initializeGame : null,
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
                    _gameCompleted ? 'NOUVELLE PARTIE' : 'COMMENCER LA PARTIE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _gameTimer.cancel();
                        _initializeGame();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        side: BorderSide(color: Color(0xFF6A11CB)),
                      ),
                      child: Text(
                        'RECOMMENCER',
                        style: TextStyle(
                          color: Color(0xFF6A11CB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _hintUsed ? null : _hint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hintUsed ? Colors.grey : Color(0xFFFF6B6B),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'INDICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

  Widget _buildMemoryCard(MemoryCard card) {
    return GestureDetector(
      onTap: () => _flipCard(card.id),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: card.isMatched
              ? Color(0xFF4ECDC4)
              : card.isFlipped
              ? _cardColor
              : Color(0xFF6A11CB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_isDarkMode ? 0.5 : 0.3),
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
          border: card.isMatched
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: card.isFlipped || card.isMatched
                ? Text(
              card.emoji,
              style: TextStyle(fontSize: 24),
              key: ValueKey(card.emoji + card.id.toString()),
            )
                : Icon(
              Icons.question_mark,
              color: Colors.white,
              size: 24,
              key: ValueKey('question${card.id}'),
            ),
          ),
        ),
      ),
    );
  }
}

class MemoryCard {
  final int id;
  final String emoji;
  final bool isFlipped;
  final bool isMatched;

  MemoryCard({
    required this.id,
    required this.emoji,
    required this.isFlipped,
    required this.isMatched,
  });

  MemoryCard copyWith({
    int? id,
    String? emoji,
    bool? isFlipped,
    bool? isMatched,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}