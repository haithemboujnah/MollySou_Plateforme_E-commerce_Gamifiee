import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mollysou/LoginScreen.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Import services
import 'ProductsByCategoryScreen.dart';
import 'services/user_service.dart';
import 'services/category_service.dart';
import 'services/event_service.dart';
import 'services/cooldown_service.dart';

import 'CartScreen.dart';
import 'VideoAdScreen.dart';
import 'WheelGameScreen.dart';
import 'PuzzleGameScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> categories = [];
  List<dynamic> events = [];
  Map<String, dynamic>? currentUser;
  int? userId;

  // User data from API
  Map<String, dynamic> userData = {
    "level": 1,
    "points": 0,
    "xpActuel": 0,
    "xpProchainNiveau": 1000,
    "rank": "BRONZE",
    "nomComplet": "Utilisateur",
    "photoProfil": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxz7qJ9pU6Xj2EJKaRDVz-9Bd0xh2LnMklGw&s"
  };

  bool _isDarkMode = false;
  bool _isLoading = true;
  Duration _wheelCooldown = Duration.zero;
  Duration _puzzleCooldown = Duration.zero;
  Duration _videoCooldown = Duration.zero;
  late Timer _timer;

  late StreamSubscription<Duration> _wheelCooldownSubscription;
  late StreamSubscription<Duration> _puzzleCooldownSubscription;
  late StreamSubscription<Duration> _videoCooldownSubscription;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _setupCooldownListeners();
  }

  void _setupCooldownListeners() {
    // Listen for wheel cooldown updates
    _wheelCooldownSubscription = CooldownManager().wheelCooldownStream.listen((duration) {
      if (mounted) {
        setState(() {
          _wheelCooldown = duration;
        });
      }
    });

    // Listen for puzzle cooldown updates
    _puzzleCooldownSubscription = CooldownManager().puzzleCooldownStream.listen((duration) {
      if (mounted) {
        setState(() {
          _puzzleCooldown = duration;
        });
      }
    });

    // Listen for video cooldown updates
    _videoCooldownSubscription = CooldownManager().videoCooldownStream.listen((duration) {
      if (mounted) {
        setState(() {
          _videoCooldown = duration;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    await _loadDarkModePreference();
    await _loadUserData();
    await _loadDataFromApi();
    await _loadCooldownsFromApi();
    _startTimer();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final result = await UserService.getCurrentUser();
    if (result['success'] == true) {
      setState(() {
        currentUser = result['user'];
        userId = result['userId'];
        // Update user data from API response
        userData = {
          "level": currentUser?['niveau'] ?? 1,
          "points": currentUser?['points'] ?? 0,
          "xpActuel": currentUser?['xpActuel'] ?? 0,
          "xpProchainNiveau": currentUser?['xpProchainNiveau'] ?? 1000,
          "rank": currentUser?['rank'] ?? "BRONZE",
          "nomComplet": currentUser?['nomComplet'] ?? "Utilisateur",
          "photoProfil": currentUser?['photoProfil'] ?? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxz7qJ9pU6Xj2EJKaRDVz-9Bd0xh2LnMklGw&s"
        };
      });
    } else {
      // If no user is logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Load categories from API
      final categoriesData = await CategoryService.getAllCategories();

      // Load events from API
      final eventsData = await EventService.getPopularEvents();

      setState(() {
        categories = categoriesData;
        events = eventsData;
      });
    } catch (e) {
      print('Error loading data: $e');
      // Fallback to default data if API fails
      _loadDefaultData();
    }
  }

  void _loadDefaultData() {
    setState(() {
      categories = [
        {"id": 1, "nom": "Vêtements", "icon": "checkroom", "color": "#FFFF6B6B"},
        {"id": 2, "nom": "Électronique", "icon": "devices", "color": "#FF4ECDC4"},
        {"id": 3, "nom": "Beauté", "icon": "spa", "color": "#FF45B7D1"},
        {"id": 4, "nom": "Restauration", "icon": "restaurant", "color": "#FF96CEB4"},
        {"id": 5, "nom": "Santé", "icon": "local_hospital", "color": "#FFFFEAA7"},
        {"id": 6, "nom": "Décoration", "icon": "home", "color": "#FFFFB6C1"},
        {"id": 7, "nom": "Enfants", "icon": "child_care", "color": "#FFDDA0DD"},
        {"id": 8, "nom": "Divertissement", "icon": "sports_esports", "color": "#FF98FB98"},
      ];

      events = [
        {"id": 1, "titre": "Festival Summer", "date": "2023-12-15", "prix": 45.0, "image": "🎵", "rating": 4.8},
        {"id": 2, "titre": "Finale Championnat", "date": "2023-12-18", "prix": 35.0, "image": "⚽", "rating": 4.9},
        {"id": 3, "titre": "Comédie Musicale", "date": "2023-12-20", "prix": 60.0, "image": "🎭", "rating": 4.7},
        {"id": 4, "titre": "Festival Jazz", "date": "2023-12-22", "prix": 55.0, "image": "🎷", "rating": 4.6},
      ];
    });
  }

  Future<void> _loadCooldownsFromApi() async {
    if (userId == null) {
      await _loadLocalCooldowns();
      return;
    }

    try {
      final cooldowns = await CooldownService.getUserCooldowns(userId!);
      print('Loaded cooldowns from API: $cooldowns');

      setState(() {
        _wheelCooldown = Duration(seconds: cooldowns['wheelCooldown'] ?? 0);
        _puzzleCooldown = Duration(seconds: cooldowns['puzzleCooldown'] ?? 0);
        _videoCooldown = Duration(seconds: cooldowns['videoCooldown'] ?? 0);
      });

      // Update cooldown manager with current values
      CooldownManager().updateWheelCooldown(_wheelCooldown);
      CooldownManager().updatePuzzleCooldown(_puzzleCooldown);
      CooldownManager().updateVideoCooldown(_videoCooldown);

    } catch (e) {
      print('Error loading cooldowns from API: $e');
      // Fallback to local cooldowns
      await _loadLocalCooldowns();
    }
  }

  Future<void> _loadLocalCooldowns() async {
    final wheelCooldown = await CooldownManager().getLocalCooldown('Spin');
    final puzzleCooldown = await CooldownManager().getLocalCooldown('Game');
    final videoCooldown = await CooldownManager().getLocalCooldown('Watch');

    setState(() {
      _wheelCooldown = wheelCooldown ?? Duration.zero;
      _puzzleCooldown = puzzleCooldown ?? Duration.zero;
      _videoCooldown = videoCooldown ?? Duration.zero;
    });

    // Update cooldown manager with current values
    CooldownManager().updateWheelCooldown(_wheelCooldown);
    CooldownManager().updatePuzzleCooldown(_puzzleCooldown);
    CooldownManager().updateVideoCooldown(_videoCooldown);
  }

  @override
  void dispose() {
    _timer.cancel();
    _wheelCooldownSubscription.cancel();
    _puzzleCooldownSubscription.cancel();
    _videoCooldownSubscription.cancel();
    super.dispose();
  }

  // Charger la préférence du mode sombre
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_wheelCooldown.inSeconds > 0) {
            _wheelCooldown = _wheelCooldown - Duration(seconds: 1);
          }
          if (_puzzleCooldown.inSeconds > 0) {
            _puzzleCooldown = _puzzleCooldown - Duration(seconds: 1);
          }
          if (_videoCooldown.inSeconds > 0) {
            _videoCooldown = _videoCooldown - Duration(seconds: 1);
          }
        });

        // Refresh cooldowns from API every 30 seconds to ensure sync
        if (timer.tick % 30 == 0) {
          _loadCooldownsFromApi();
        }
      }
    });
  }


  // Sauvegarder la préférence du mode sombre
  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  // Basculer le mode sombre
  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    _saveDarkModePreference(_isDarkMode);
  }

  // Logout function
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text(
          "Déconnexion",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?",
          style: TextStyle(color: _secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await UserService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Déconnexion", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Formater le temps restant
  String _formatCooldown(Duration duration) {
    if (duration.inSeconds <= 0) return 'Prêt';

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h${minutes.toString().padLeft(2, '0')}';
      } else {
        return '${hours}h';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Vérifier si un jeu est en cooldown
  bool _isOnCooldown(Duration cooldown) {
    return cooldown.inSeconds > 0;
  }

  // Obtenir la couleur du texte en fonction du cooldown
  Color _getCooldownTextColor(Duration cooldown) {
    if (_isOnCooldown(cooldown)) {
      return Colors.red;
    } else {
      return _isDarkMode ? Colors.green[300]! : Colors.green[300]!;
    }
  }

  // Convert hex color string to Color
  Color _hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  // Get icon from string
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'checkroom': return Icons.checkroom;
      case 'devices': return Icons.devices;
      case 'spa': return Icons.spa;
      case 'restaurant': return Icons.restaurant;
      case 'local_hospital': return Icons.local_hospital;
      case 'home': return Icons.home;
      case 'child_care': return Icons.child_care;
      case 'sports_esports': return Icons.sports_esports;
      default: return Icons.category;
    }
  }

  Map<String, dynamic> getRankInfo(int level) {
    if (level >= 200) {
      return {
        "name": "DIAMOND",
        "color": Color(0xFF1E3A8A),
        "borderColor": Color(0xFF0BC5EA),
        "discount": "50% discount",
        "gradient": [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      };
    } else if (level >= 100) {
      return {
        "name": "PLATINUM",
        "color": Color(0xFF0BC5EA),
        "borderColor": Color(0xFF1E3A8A),
        "discount": "20% discount",
        "gradient": [Color(0xFF06B6D4), Color(0xFF0BC5EA)],
      };
    } else if (level >= 50) {
      return {
        "name": "GOLD",
        "color": Color(0xFFFFD700),
        "borderColor": Color(0xFFFFA500),
        "discount": "15% discount",
        "gradient": [Color(0xFFFFF8DC), Color(0xFFFFD700)],
      };
    } else if (level >= 30) {
      return {
        "name": "SILVER",
        "color": Color(0xFFC0C0C0),
        "borderColor": Color(0xFFA9A9A9),
        "discount": "10% discount",
        "gradient": [Color(0xFFF0F0F0), Color(0xFFC0C0C0)],
      };
    } else {
      return {
        "name": "BRONZE",
        "color": Color(0xFFCD7F32),
        "borderColor": Color(0xFF8B4513),
        "discount": "5% discount",
        "gradient": [Color(0xFFDEB887), Color(0xFFCD7F32)],
      };
    }
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _appBarColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _searchBarColor => _isDarkMode ? Color(0xFF0F3460) : Colors.white;
  Color get _chatbotBackgroundColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _inputBackgroundColor => _isDarkMode ? Color(0xFF0F3460) : Colors.grey[50]!;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
          ),
        ),
      );
    }

    final rankInfo = getRankInfo(userData["level"]);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context, rankInfo),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Section Points et Niveau
            _buildPointsSection(context),
            SizedBox(height: 16),

            // Barre de recherche améliorée
            _buildSearchBar(),
            SizedBox(height: 24),

            // Section Catégories agrandie
            _buildCategoriesSection(),
            SizedBox(height: 24),

            // Section Événements améliorée
            _buildEventsSection(),
            SizedBox(height: 24),

            // Assistant IA avec input direct
            _buildChatbotSection(context),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, Map<String, dynamic> rankInfo) {
    return AppBar(
      backgroundColor: _appBarColor,
      elevation: 1,
      leading: Container(
        margin: EdgeInsets.all(8),
        child: _buildPointsIcon(
          Icons.logout,
          Colors.white,
          Color(0xFFAA3E3E),
          _logout, // Updated to use logout function
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bonjour",
            style: GoogleFonts.aBeeZee(
              fontSize: 14,
              color: _secondaryTextColor,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            userData["nomComplet"],
            style: GoogleFonts.aBeeZee(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: _textColor,
            ),
          )
        ],
      ),
      actions: [
        // Profil avec niveau et cadre animé
        _buildAnimatedProfileWithLevel(rankInfo),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAnimatedProfileWithLevel(Map<String, dynamic> rankInfo) {
    double progressValue = (userData["xpActuel"] / userData["xpProchainNiveau"]).toDouble();
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(height: 4),
            Text(
              "Niveau ${userData["level"]}",
              style: TextStyle(
                fontSize: 12,
                color: _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Container(
              width: 80,
              height: 6,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Stack(
                children: [
                  Container(
                    width: 80 * progressValue,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [rankInfo["borderColor"], rankInfo["color"]],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2),
            Text(
              "${userData["xpActuel"]}/${userData["xpProchainNiveau"]} XP",
              style: TextStyle(
                fontSize: 10,
                color: _secondaryTextColor,
              ),
            ),
          ],
        ),
        SizedBox(width: 12),

        // Cadre de profil animé avec le rank
        _buildAnimatedProfileFrame(rankInfo),
      ],
    );
  }

  Widget _buildAnimatedProfileFrame(Map<String, dynamic> rankInfo) {
    return Container(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animation du cadre
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: rankInfo["gradient"],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: rankInfo["borderColor"].withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
            child: CircularProgressIndicator(
              value: userData["xpActuel"] / userData["xpProchainNiveau"],
              strokeWidth: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(rankInfo["borderColor"]),
            ),
          ),

          // Photo de profil
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: rankInfo["borderColor"],
                width: 2,
              ),
              image: DecorationImage(
                image: NetworkImage(userData["photoProfil"]),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Badge du rank en bas à droite
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: rankInfo["color"],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(BuildContext context) {
    final rankInfo = getRankInfo(userData["level"]);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: rankInfo["gradient"],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: rankInfo["borderColor"].withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            // Discount info
            Text(
              rankInfo["discount"],
              style: GoogleFonts.aBeeZee(
                color: rankInfo["borderColor"],
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                // Shopping cart on the left
                _buildPointsIcon(Icons.shopping_cart, Colors.white, Color(0xFFAA8B3E), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                }),
                SizedBox(width: 12),
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: _buildPointsIcon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    Colors.white,
                    _isDarkMode ? Color(0xFFFFD700) : Color(0xFF000000),
                    _toggleDarkMode,
                  ),
                ),
                Spacer(),
                // Other icons on the right
                Row(
                  children: [
                    // Wheel Game
                    Column(
                      children: [
                        _buildPointsIcon(
                          Icons.casino,
                          _isOnCooldown(_wheelCooldown) ? Colors.white70 : Colors.white,
                          _isOnCooldown(_wheelCooldown) ? Colors.grey : Color(0xFFFF6B6B),
                          _isOnCooldown(_wheelCooldown) ? () {} : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => WheelGameScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCooldown(_wheelCooldown),
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12,
                            color: _getCooldownTextColor(_wheelCooldown),
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),

                    // Puzzle Game
                    Column(
                      children: [
                        _buildPointsIcon(
                          Icons.extension,
                          _isOnCooldown(_puzzleCooldown) ? Colors.white70 : Colors.white,
                          _isOnCooldown(_puzzleCooldown) ? Colors.grey : Color(0xFF4ECDC4),
                          _isOnCooldown(_puzzleCooldown) ? () {} : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PuzzleGameScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCooldown(_puzzleCooldown),
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12,
                            color: _getCooldownTextColor(_puzzleCooldown),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),

                    // Video Ad
                    Column(
                      children: [
                        _buildPointsIcon(
                          Icons.card_giftcard,
                          _isOnCooldown(_videoCooldown) ? Colors.white70 : Colors.white,
                          _isOnCooldown(_videoCooldown) ? Colors.grey : Color(0xFF45B7D1),
                          _isOnCooldown(_videoCooldown) ? () {} : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => VideoAdScreen()),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCooldown(_videoCooldown),
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12,
                            color: _getCooldownTextColor(_videoCooldown),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsIcon(IconData icon, Color iconColor, Color bgColor, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: () async {
          onPressed();
          // Refresh cooldowns when returning from game screens
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            await _loadCooldownsFromApi();
          }
        },
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _searchBarColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_isDarkMode ? 0.3 : 0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 20),
            Icon(Icons.search, color: Color(0xFF6A11CB), size: 24),
            SizedBox(width: 15),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Rechercher des produits...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: _isDarkMode ? Colors.white54 : Colors.grey[500],
                      fontSize: 16
                  ),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: _textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Catégories",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF6A11CB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Voir tout",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryItem(categories[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index) {
    final color = category['color'] != null ? _hexToColor(category['color']) : Color(0xFFFF6B6B);
    final icon = category['icon'] != null ? _getIconFromString(category['icon']) : Icons.category;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsByCategoryScreen(category: category),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: EdgeInsets.only(
          left: index == 0 ? 20 : 12,
          right: index == categories.length - 1 ? 20 : 0,
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            SizedBox(height: 12),
            Text(
              category['nom'] ?? 'Catégorie',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Événements Populaires",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF6A11CB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Voir tout",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(events[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final date = event['date'] != null ? _formatEventDate(event['date']) : 'Date inconnue';
    final price = event['prix'] != null ? '€${event['prix']}' : '€0';
    final rating = event['rating']?.toString() ?? '0.0';

    return Container(
      width: 200,
      margin: EdgeInsets.only(
        left: index == 0 ? 20 : 15,
        right: index == events.length - 1 ? 20 : 0,
      ),
      child: Card(
        elevation: 4,
        color: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    event['image'] ?? '🎵',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                event['titre'] ?? 'Événement',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.3,
                  color: _textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    date,
                    style: TextStyle(
                      color: Color(0xFF6A11CB),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Réserver",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)}';
    } catch (e) {
      return 'Date invalide';
    }
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  Widget _buildChatbotSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _chatbotBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(_isDarkMode ? 0.3 : 0.1),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Assistant IA",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Comment puis-je vous aider ?",
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 55,
              decoration: BoxDecoration(
                color: _inputBackgroundColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: _textColor),
                      decoration: InputDecoration(
                        hintText: "Posez votre question...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: _isDarkMode ? Colors.white54 : Colors.grey[500]
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}