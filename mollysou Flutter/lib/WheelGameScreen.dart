import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_service.dart';
import 'services/cooldown_service.dart';

class WheelGameScreen extends StatefulWidget {
  @override
  _WheelGameScreenState createState() => _WheelGameScreenState();
}

class _WheelGameScreenState extends State<WheelGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _angle = 0.0;
  bool _isSpinning = false;
  int _pointsWon = 0;
  bool _showResult = false;
  bool _isDarkMode = false;
  bool _canSpin = true;
  DateTime? _lastSpinTime;
  Duration _timeRemaining = Duration.zero;
  int? _userId;

  final List<Map<String, dynamic>> _rewards = [
    {'points': 50, 'color': Color(0xFFFF6B6B), 'probability': 35},
    {'points': 100, 'color': Color(0xFF4ECDC4), 'probability': 30},
    {'points': 300, 'color': Color(0xFF45B7D1), 'probability': 15},
    {'points': 700, 'color': Color(0xFF96CEB4), 'probability': 12},
    {'points': 1000, 'color': Color(0xFFFFEAA7), 'probability': 8},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
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
    }
  }

  Future<void> _loadCooldownsFromApi() async {
    if (_userId == null) return;

    try {
      final cooldowns = await CooldownService.getUserCooldowns(_userId!);

      final wheelCooldownSeconds = cooldowns['wheelCooldown'] ?? 0;
      setState(() {
        _timeRemaining = Duration(seconds: wheelCooldownSeconds);
        _canSpin = wheelCooldownSeconds <= 0;
      });

      if (wheelCooldownSeconds > 0) {
        _startTimer();
      }
    } catch (e) {
      print('Error loading cooldowns from API: $e');
      // Fallback to local storage
      await _loadLocalCooldowns();
    }
  }

  Future<void> _loadLocalCooldowns() async {
    final prefs = await SharedPreferences.getInstance();

    final lastSpinMillis = prefs.getInt('lastSpinTime');
    if (lastSpinMillis != null) {
      final lastSpinTime = DateTime.fromMillisecondsSinceEpoch(lastSpinMillis);
      final nextSpinTime = lastSpinTime.add(Duration(hours: 24));
      final now = DateTime.now();

      if (now.isBefore(nextSpinTime)) {
        setState(() {
          _timeRemaining = nextSpinTime.difference(now);
          _canSpin = false;
        });
        _startTimer();
      } else {
        setState(() {
          _canSpin = true;
          _timeRemaining = Duration.zero;
        });
      }
    }
  }

  void _startTimer() {
    // Update timer every second
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          if (_timeRemaining.inSeconds > 0) {
            _timeRemaining = _timeRemaining - Duration(seconds: 1);
          } else {
            _canSpin = true;
          }
        });

        if (_timeRemaining.inSeconds > 0) {
          _startTimer();
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

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (_isSpinning || !_canSpin) return;

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _pointsWon = 0;
    });

    final random = Random();

    // Choose target segment for fair probability-based spin
    final totalProb = _rewards.fold<int>(0, (sum, r) => sum + (r['probability'] as int));
    int randomValue = random.nextInt(totalProb);
    int cumulative = 0;
    int selectedIndex = 0;

    for (int i = 0; i < _rewards.length; i++) {
      cumulative += _rewards[i]['probability'] as int;
      if (randomValue < cumulative) {
        selectedIndex = i;
        break;
      }
    }

    // Compute target angle
    double segmentAngle = (2 * pi) / _rewards.length;
    double targetAngle = (-(selectedIndex * segmentAngle) - pi / 2) + (2 * pi * 5); // 5 full spins

    _controller.duration = Duration(seconds: 3);
    _controller.reset();
    _controller.forward();

    _controller.addListener(() {
      setState(() {
        _angle = targetAngle * _controller.value;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateResult(selectedIndex);
      }
    });
  }

  void _calculateResult(int index) async {
    final reward = _rewards[index];

    setState(() {
      _pointsWon = reward['points'];
      _isSpinning = false;
      _showResult = true;
      _canSpin = false;
    });

    // Set cooldown to 24 hours
    final newCooldown = Duration(hours: 24);
    setState(() {
      _timeRemaining = newCooldown;
    });

    // Update cooldown in API
    if (_userId != null) {
      try {
        await CooldownService.updateCooldown(_userId!, 'wheel');
        print('Wheel cooldown updated in API');
      } catch (e) {
        print('Error updating cooldown in API: $e');
        // Fallback to local storage
        await CooldownManager().saveLocalCooldown('Spin', newCooldown);
      }
    } else {
      await CooldownManager().saveLocalCooldown('Spin', newCooldown);
    }

    // Notify cooldown manager
    CooldownManager().updateWheelCooldown(newCooldown);

    _startTimer();
  }

  Future<void> _saveLastSpinTimeLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSpinTime', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Roue de la Chance', style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // En-tête avec timer
            Container(
              padding: EdgeInsets.all(20),
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
                  Icon(Icons.casino, size: 40, color: Color(0xFF6A11CB)),
                  SizedBox(height: 10),
                  Text(
                    'Tournez la roue !',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Gagnez jusqu\'à 1000 points',
                    style: TextStyle(
                      color: _secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Affichage du timer
                  if (!_canSpin)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Color(0xFF0F3460) : Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 16,
                              color: _isDarkMode ? Colors.blue[200] : Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            'Prochain tour: $_timeRemainingText',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.blue[200] : Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Roue
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Roue
                  Container(
                    width: 280,
                    height: 280,
                    child: Transform.rotate(
                      angle: _angle,
                      child: CustomPaint(
                        painter: WheelPainter(_rewards),
                      ),
                    ),
                  ),

                  // Centre de la roue
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFF6A11CB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6A11CB).withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        )
                      ],
                    ),
                    child: Icon(Icons.star, color: Colors.white, size: 30),
                  ),

                  // Pointeur
                  Positioned(
                    top: 20,
                    child: Icon(Icons.arrow_drop_down, size: 40, color: Colors.red),
                  ),
                ],
              ),
            ),

            // Résultat
            if (_showResult)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.green[900]! : Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, color: Colors.green),
                    SizedBox(width: 10),
                    Text(
                      'Félicitations ! Vous gagnez $_pointsWon points',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.green[100] : Colors.green[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Bouton spin
            Container(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: (_isSpinning || !_canSpin) ? null : _spinWheel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSpin ? Color(0xFF6A11CB) : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: _canSpin ? 5 : 0,
                ),
                child: _isSpinning
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : !_canSpin
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'PROCHAIN TOUR: $_timeRemainingText',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
                    : Text(
                  'TOURNER LA ROUE',
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
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> rewards;

  WheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint();
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    final sweepAngle = 2 * 3.14159 / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final startAngle = i * sweepAngle;
      final color = rewards[i]['color'];

      // Dessiner le segment
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dessiner le texte
      final textAngle = startAngle + sweepAngle / 2;
      final textX = center.dx + (radius - 40) * cos(textAngle);
      final textY = center.dy + (radius - 40) * sin(textAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rewards[i]['points']}',
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
    }

    // Bordure
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}