import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mollysou/LoginScreen.dart';
import 'package:mollysou/services/SearchService.dart';
import 'package:mollysou/services/chatbot_service.dart';
import 'package:mollysou/services/cooldown_manager.dart';
import 'package:mollysou/services/event_recommendation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'ProductsByCategoryScreen.dart';
import 'ReflexGameScreen.dart';
import 'components/EventDetailsSheet.dart';
import 'components/Sidebar.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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
    "rank": "UNRANKED",
    "nomComplet": "Utilisateur",
    "photoProfil": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxz7qJ9pU6Xj2EJKaRDVz-9Bd0xh2LnMklGw&s"
  };

  bool _isDarkMode = false;
  bool _isLoading = true;
  Duration _wheelCooldown = Duration.zero;
  Duration _puzzleCooldown = Duration.zero;
  Duration _videoCooldown = Duration.zero;
  Duration _reflexCooldown = Duration.zero;
  late Timer _timer;

  late StreamSubscription<Duration> _wheelCooldownSubscription;
  late StreamSubscription<Duration> _puzzleCooldownSubscription;
  late StreamSubscription<Duration> _videoCooldownSubscription;
  late StreamSubscription<Duration> _reflexCooldownSubscription;

  bool _isSidebarOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    _reflexCooldownSubscription = CooldownManager().reflexCooldownStream.listen((duration) {
      if (mounted) {
        setState(() {
          _reflexCooldown = duration;
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
          "rank": currentUser?['rank'] ?? "UNRANKED",
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  // Add gesture detector for swipe
  Widget _buildWithSidebar(Widget child) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        // Swiping from right to left to open sidebar
        if (details.delta.dx < -10 && !_isSidebarOpen) {
          _toggleSidebar();
        }
        // Swiping from left to right to close sidebar
        if (details.delta.dx > 10 && _isSidebarOpen) {
          _toggleSidebar();
        }
      },
      child: Stack(
        children: [
          // Main content
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
              _isSidebarOpen ? -MediaQuery.of(context).size.width * 0.85 : 0,
              0,
              0,
            ),
            child: child,
          ),

          // Sidebar
          if (_isSidebarOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Sidebar(
                userData: userData,
                onClose: _toggleSidebar,
                isDarkMode: _isDarkMode,
                toggleDarkMode: _toggleDarkMode,
              ),
            ),

          // Overlay when sidebar is open
          if (_isSidebarOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: MediaQuery.of(context).size.width * 0.85,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadDataFromApi() async {
    try {
      // Load categories from API
      final categoriesData = await CategoryService.getAllCategories();

      // Load events with recommendations
      await _loadEventsWithRecommendations();

      setState(() {
        categories = categoriesData;
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
        _reflexCooldown = Duration(seconds: cooldowns['reflexCooldown'] ?? 0);
      });

      // Update cooldown manager with current values
      CooldownManager().updateWheelCooldown(_wheelCooldown);
      CooldownManager().updatePuzzleCooldown(_puzzleCooldown);
      CooldownManager().updateVideoCooldown(_videoCooldown);
      CooldownManager().updateReflexCooldown(_reflexCooldown);

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
    final reflexCooldown= await CooldownManager().getLocalCooldown('Reflex');

    setState(() {
      _wheelCooldown = wheelCooldown ?? Duration.zero;
      _puzzleCooldown = puzzleCooldown ?? Duration.zero;
      _videoCooldown = videoCooldown ?? Duration.zero;
      _reflexCooldown = reflexCooldown ?? Duration.zero;
    });

    // Update cooldown manager with current values
    CooldownManager().updateWheelCooldown(_wheelCooldown);
    CooldownManager().updatePuzzleCooldown(_puzzleCooldown);
    CooldownManager().updateVideoCooldown(_videoCooldown);
    CooldownManager().updateReflexCooldown(_reflexCooldown);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _wheelCooldownSubscription.cancel();
    _puzzleCooldownSubscription.cancel();
    _videoCooldownSubscription.cancel();
    _reflexCooldownSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh data
      _refreshUserData();
      _loadCooldownsFromApi();
    }
  }

  Future<void> _refreshUserData() async {
    try {
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
            "rank": currentUser?['rank'] ?? "UNRANKED",
            "nomComplet": currentUser?['nomComplet'] ?? "Utilisateur",
            "photoProfil": currentUser?['photoProfil'] ?? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxz7qJ9pU6Xj2EJKaRDVz-9Bd0xh2LnMklGw&s"
          };
        });
        print('User data refreshed: Level ${userData["level"]}, Points ${userData["points"]}');
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
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
          if (_reflexCooldown.inSeconds > 0) {
            _reflexCooldown = _reflexCooldown - Duration(seconds: 1);
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
    } else if (level >= 10) {
      return {
        "name": "BRONZE",
        "color": Color(0xFFCD7F32),
        "borderColor": Color(0xFF8B4513),
        "discount": "5% discount",
        "gradient": [Color(0xFFDEB887), Color(0xFFCD7F32)],
      };
    } else {
      return {
        "name": "UNRANKED",
        "color": Color(0x00A0A2A6),
        "borderColor": Color(0xFF636363),
        "discount": "0% discount",
        "gradient": [ Color(0x00FFFFFF), Color(0x00FFFFFF)],
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

  int _clickCount = 0;
  DateTime? _lastClickTime;

  void _handleTripleClick() {
    final now = DateTime.now();

    // Réinitialiser le compteur si trop de temps s'est écoulé
    if (_lastClickTime == null || now.difference(_lastClickTime!) > Duration(seconds: 1)) {
      _clickCount = 1;
    } else {
      _clickCount++;
    }

    _lastClickTime = now;

    // Si triple clic détecté
    if (_clickCount >= 3) {
      _clickCount = 0; // Réinitialiser le compteur
      _showTripleClickAnimation();
      _toggleDarkMode(); // Basculer le mode
    }
  }

  void _showTripleClickAnimation() {
    // Afficher un snackbar de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isDarkMode ? Color(0xFF6A11CB) : Color(0xFF2575FC),
        content: Row(
          children: [
            Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _isDarkMode ? "Mode clair activé" : "Mode sombre activé",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

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
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context, rankInfo),
      body: GestureDetector(
        onTap: _handleTripleClick, // Détecter le triple clic n'importe où sur l'écran
        child: _buildWithSidebar(
          SingleChildScrollView(
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
                // Shopping cart with text "Shop"
                Column(
                  children: [
                    _buildPointsIcon(
                      Icons.shopping_cart,
                      Colors.white,
                      Color(0xFFAA8B3E),
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CartScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Achat",
                      style: GoogleFonts.aBeeZee(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Spacer(),
                // Other icons on the right
                Row(
                  children: [
                    // Reflex Game
                    Column(
                      children: [
                        _buildPointsIcon(
                          Icons.bolt,
                          _isOnCooldown(_reflexCooldown) ? Colors.white70 : Colors.white,
                          _isOnCooldown(_reflexCooldown) ? Colors.grey : Color(0xFFFF6B6B),
                          _isOnCooldown(_reflexCooldown) ? () {} : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReflexGameScreen(
                                  onPointsEarned: () {
                                    _loadUserData();
                                    _loadCooldownsFromApi();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCooldown(_reflexCooldown),
                          style: GoogleFonts.aBeeZee(
                            fontSize: 12,
                            color: _getCooldownTextColor(_reflexCooldown),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
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
                              MaterialPageRoute(
                                builder: (context) => WheelGameScreen(
                                  onPointsEarned: () {
                                    _loadUserData();
                                    _loadCooldownsFromApi();
                                  },
                                ),
                              ),
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
                              MaterialPageRoute(
                                builder: (context) => PuzzleGameScreen(
                                  onPointsEarned: () {
                                    _loadUserData();
                                    _loadCooldownsFromApi();
                                  },
                                ),
                              ),
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
                              MaterialPageRoute(
                                builder: (context) => VideoAdScreen(
                                  onPointsEarned: () {
                                    _loadUserData();
                                    _loadCooldownsFromApi();
                                  },
                                ),
                              ),
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
          // Store current data before navigation
          final oldLevel = userData["level"];
          final oldPoints = userData["points"];

          onPressed();

          // Wait a bit for the game to complete and return
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            // Refresh user data and cooldowns
            await _refreshUserData();
            await _loadCooldownsFromApi();

            // Check if level changed
            final newLevel = userData["level"];
            final newPoints = userData["points"];

            if (newLevel > oldLevel) {
              _showLevelUpNotification(newLevel);
            } else if (newPoints > oldPoints) {
              _showPointsEarnedNotification(newPoints - oldPoints);
            }
          }
        },
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showLevelUpNotification(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0xFFFFD700),
        content: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.black),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Félicitations ! Vous êtes maintenant niveau $newLevel',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showPointsEarnedNotification(int pointsEarned) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Color(0xFF6A11CB),
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '+$pointsEarned points gagnés !',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Rechercher des catégories...",
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
                onChanged: (value) {
                  _performSearch(value);
                },
                onTap: () {
                  // Optionnel: Ouvrir un écran de recherche dédié
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: _secondaryTextColor),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
          ],
        ),
      ),
    );
  }

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  String _searchType = 'all';
  bool _isRecommendationBased = false;

// Méthode pour effectuer la recherche
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await SearchService.searchCategories(query, userId);

      setState(() {
        _searchResults = result['categories'] ?? [];
        _searchType = result['search_type'] ?? 'normal';
        _isRecommendationBased = result['recommendation_based'] ?? false;
        _isSearching = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Widget _buildCategoriesSection() {
    final displayCategories = _isSearching ? [] : (_searchController.text.isNotEmpty ? _searchResults : categories);
    final isSearchActive = _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isSearchActive)
                Text(
                  "Catégories",
                  style: GoogleFonts.aBeeZee(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      fontStyle: FontStyle.italic
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Résultats de recherche",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      /*if (_isRecommendationBased)
                        Text(
                          "Recommandations basées sur votre recherche",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),*/
                    ],
                  ),
                ),

              if (!isSearchActive)
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

        if (_isSearching)
          _buildSearchLoading()
        else if (isSearchActive && _searchResults.isEmpty)
          _buildNoResults()
        else
          _buildCategoriesList(displayCategories, isSearchActive),
      ],
    );
  }

  Widget _buildSearchLoading() {
    return Container(
      height: 130,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
            ),
            SizedBox(height: 10),
            Text(
              "Recherche en cours...",
              style: TextStyle(
                color: _secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      height: 130,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: _secondaryTextColor,
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              "Aucun résultat trouvé",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Essayez d'autres termes comme 'homme', 'femme', 'électronique'...",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(List<dynamic> categoriesToShow, bool isSearchActive) {
    return Container(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          return _buildCategoryItem(categoriesToShow[index], index, isSearchActive);
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category, int index, bool isSearchActive) {
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
        width: isSearchActive ? 120 : 100,
        margin: EdgeInsets.only(
          left: index == 0 ? 20 : 12,
          right: index == categories.length - 1 ? 20 : 0,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isSearchActive ? 90 : 80,
                height: isSearchActive ? 90 : 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isSearchActive ? 36 : 32),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      category['nom'] ?? 'Catégorie',
                      style: TextStyle(
                        fontSize: isSearchActive ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSearchActive && _isRecommendationBased) ...[
                    SizedBox(width: 4),
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                  ],
                ],
              ),
              if (isSearchActive && _isRecommendationBased)
                Text(
                  "Recommandé",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Événements Recommandés",
                    style: GoogleFonts.aBeeZee(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ],
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

        if (_isLoadingEvents)
          _buildEventsLoading()
        else if (events.isEmpty)
          _buildNoEvents()
        else
          Container(
            height: 250, // Fixed height for the scrollable area
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index], index);
              },
            ),
          ),
      ],
    );
  }

  bool _isLoadingEvents = false;
  bool _eventsRecommendationBased = false;

  Widget _buildEventsLoading() {
    return Container(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
            ),
            SizedBox(height: 10),
            Text(
              "Chargement des événements...",
              style: TextStyle(
                color: _secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoEvents() {
    return Container(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              color: _secondaryTextColor,
              size: 40,
            ),
            SizedBox(height: 10),
            Text(
              "Aucun événement disponible",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Revenez plus tard pour découvrir\nnos nouveaux événements",
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final date = event['date'] != null ? _formatEventDate(event['date']) : 'Date inv.';
    final price = event['prix'] != null ? '${event['prix']} DT' : '0 DT';
    final rating = event['rating']?.toString() ?? '0.0';
    final type = event['type'] ?? 'ÉVÉNEMENT';
    final recommendationReason = event['recommendation_reason'];

    return Container(
      width: 200, // Reduced width to ensure no overflow
      margin: EdgeInsets.only(right: 15),
      child: Card(
        elevation: 4,
        color: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 220, // Minimum height constraint
            maxHeight: 240, // Maximum height constraint
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(12), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
                  children: [
                    // Header section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge de type
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getEventTypeColor(type),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            type.length > 8 ? '${type.substring(0, 8)}..' : type,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Image de l'événement
                        Container(
                          height: 70, // Reduced height
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              event['image'] ?? '🎉',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),

                    // Content section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Titre
                          Text(
                            event['titre'] ?? 'Événement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                              color: _textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),

                          // Lieu et date
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 10, color: _secondaryTextColor),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event['lieu'] ?? 'Lieu inconnu',
                                      style: TextStyle(
                                        color: _secondaryTextColor,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 10, color: _secondaryTextColor),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      date,
                                      style: TextStyle(
                                        color: Color(0xFF6A11CB),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 6),

                          // Rating et prix
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 10),
                              SizedBox(width: 2),
                              Text(
                                rating.length > 4 ? rating.substring(0, 4) : rating,
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Text(
                                price,
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Button section
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 28, // Reduced height
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextButton(
                        onPressed: () {
                          _showEventDetails(event);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          "Réserver",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge de recommandation
              if (recommendationReason != null && _eventsRecommendationBased)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up, color: Colors.white, size: 8),
                        SizedBox(width: 2),
                        Text(
                          "Pour vous",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor(String? type) {
    switch (type?.toUpperCase()) {
      case 'CONCERT':
        return Color(0xFFFF6B6B);
      case 'SPORT':
        return Color(0xFF4ECDC4);
      case 'THEATRE':
        return Color(0xFF45B7D1);
      case 'CULTURE':
        return Color(0xFF96CEB4);
      case 'ESPORT':
        return Color(0xFF2575FC);
      case 'GASTRONOMIE':
        return Color(0xFFFFB6C1);
      case 'HUMOUR':
        return Color(0xFFDDA0DD);
      case 'DANSE':
        return Color(0xFF98FB98);
      case 'AUTO':
        return Color(0xFFFFA500);
      case 'JEUX':
        return Color(0xFF8A2BE2);
      default:
        return Color(0xFF6A11CB);
    }
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return EventDetailsSheet(event: event, isDarkMode: _isDarkMode);
      },
    );
  }

  Future<void> _loadEventsWithRecommendations() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final result = await EventRecommendationService.getRecommendedEvents(userId);

      setState(() {
        events = result['events'] ?? [];
        _eventsRecommendationBased = result['recommendation_based'] ?? false;
        _isLoadingEvents = false;
      });

      print('Loaded ${events.length} recommended events for user $userId');

    } catch (e) {
      print('Error loading recommended events: $e');
      // Fallback to popular events
      try {
        final popularResult = await EventRecommendationService.getPopularEvents();
        setState(() {
          events = popularResult['events'] ?? [];
          _eventsRecommendationBased = false;
          _isLoadingEvents = false;
        });
      } catch (e2) {
        print('Error loading popular events: $e2');
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
  }


  String _formatEventDate(dynamic dateInput) {
    try {
      if (dateInput == null) return 'Date inv.';

      String dateString = dateInput.toString();

      // Handle "Thu, 11 Dec 2025 00:00:00 GMT" format
      if (dateString.contains(',')) {
        // Split by spaces and extract day and month
        final parts = dateString.split(' ');
        if (parts.length >= 4) {
          final day = parts[1]; // "11"
          final monthAbbr = parts[2]; // "Dec"

          // Convert English month abbreviation to French
          final monthMap = {
            'Jan': 'Jan', 'Feb': 'Fév', 'Mar': 'Mar', 'Apr': 'Avr',
            'May': 'Mai', 'Jun': 'Jun', 'Jul': 'Jul', 'Aug': 'Aoû',
            'Sep': 'Sep', 'Oct': 'Oct', 'Nov': 'Nov', 'Dec': 'Déc'
          };

          final month = monthMap[monthAbbr] ?? monthAbbr;
          return '$day $month';
        }
      }

      // Fallback to regular parsing
      final date = DateTime.parse(dateString.split(' ')[0]);
      final month = _getMonthName(date.month);
      final day = date.day;

      return '$day $month';
    } catch (e) {
      return 'Date inv.';
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
                        "Assistant IA MollySou",
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Je vous aide à trouver les meilleurs produits !",
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

            // Réponse du chatbot
            if (_showChatResponse && _currentBotResponse.isNotEmpty)
              _buildBotResponse(),

            // Suggestions rapides
            if (_currentSuggestions.isNotEmpty && !_showChatResponse)
              _buildQuickSuggestions(),

            SizedBox(height: 12),

            // Zone de chat
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBotResponse() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF0F3460) : Color(0xFF6A11CB).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF6A11CB).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, color: Color(0xFF6A11CB), size: 16),
              SizedBox(width: 8),
              Text(
                "Assistant MollySou",
                style: TextStyle(
                  color: Color(0xFF6A11CB),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 16, color: _secondaryTextColor),
                onPressed: () {
                  setState(() {
                    _showChatResponse = false;
                    _currentBotResponse = "";
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _currentBotResponse,
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          SizedBox(height: 8),
          // Boutons d'action
          _buildResponseActions(),
        ],
      ),
    );
  }

  Widget _buildResponseActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(Icons.search, size: 16),
            label: Text("Voir les produits"),
            onPressed: () {
              // Naviguer vers la recherche
              _chatController.text = _currentBotResponse.split('\n').first;
              _performSearch(_currentBotResponse.split('\n').first);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF6A11CB),
              side: BorderSide(color: Color(0xFF6A11CB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.chat, size: 16),
          label: Text("Discuter"),
          onPressed: _showExtendedChat,
          style: OutlinedButton.styleFrom(
            foregroundColor: _secondaryTextColor,
            side: BorderSide(color: _secondaryTextColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  final TextEditingController _chatController = TextEditingController();
  bool _isChatLoading = false;
  List<Map<String, dynamic>> _chatMessages = [];
  List<String> _currentSuggestions = [];
  bool _showSuggestions = false;
  bool _showChatResponse = false;
  String _currentBotResponse = "";

  Widget _buildQuickSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggestions rapides:",
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _currentSuggestions.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _chatController.text = _currentSuggestions[index];
                  _handleChatMessage(_currentSuggestions[index]);
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Color(0xFF0F3460) : Color(0xFF6A11CB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF6A11CB).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _currentSuggestions[index],
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Color(0xFF6A11CB),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildChatInput() {
    return Column(
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: _inputBackgroundColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(color: _textColor),
                      decoration: InputDecoration(
                        hintText: "Ex: Produits moins de 100 DT...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: _isDarkMode ? Colors.white54 : Colors.grey[500]
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _showSuggestions = true;
                            _showChatResponse = false;
                          });
                          _getChatSuggestions(value);
                        }
                      },
                      onTap: () {
                        setState(() {
                          _showSuggestions = true;
                        });
                      },
                      onSubmitted: (value) {
                        _handleChatMessage(value);
                      },
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
                    child: IconButton(
                      icon: _isChatLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isChatLoading ? null : () {
                        _handleChatMessage(_chatController.text);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Suggestions en temps réel
        if (_showSuggestions && _currentSuggestions.isNotEmpty && !_showChatResponse)
          _buildRealTimeSuggestions(),
      ],
    );
  }

  Widget _buildRealTimeSuggestions() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Suggestions:",
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _chatController.text = suggestion;
                  _handleChatMessage(suggestion);
                  setState(() {
                    _showSuggestions = false;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF6A11CB).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _getChatSuggestions(String query) async {
    if (query.isEmpty) {
      _loadGeneralSuggestions();
      return;
    }

    try {
      final result = await ChatbotService.getSuggestions(query);
      setState(() {
        _currentSuggestions = List<String>.from(result['suggestions'] ?? []);
      });
    } catch (e) {
      print('Error getting suggestions: $e');
      _loadGeneralSuggestions();
    }
  }

  void _loadGeneralSuggestions() {
    setState(() {
      _currentSuggestions = [
        "Produits moins de 50 DT",
        "Meilleurs smartphones",
        "Cadeaux pour femme",
        "Promotions du moment",
        "Nouveautés beauté",
        "Je cherche des vêtements",
        "Budget maximum 100 DT",
        "Articles populaires"
      ];
    });
  }

  void _handleChatMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _isChatLoading = true;
      _showSuggestions = false;
      _showChatResponse = false;
    });

    // Effacer le champ de saisie
    _chatController.clear();

    try {
      final response = await ChatbotService.sendMessage(message, userId);

      setState(() {
        _currentBotResponse = response['response'] ?? "Désolé, je n'ai pas pu comprendre votre demande.";
        _showChatResponse = true;
        _isChatLoading = false;

        // Mettre à jour les suggestions basées sur la réponse
        if (response['suggestions'] != null) {
          _currentSuggestions = List<String>.from(response['suggestions']);
        }
      });

    } catch (e) {
      setState(() {
        _currentBotResponse = "Désolé, je rencontre des difficultés techniques. Veuillez réessayer.";
        _showChatResponse = true;
        _isChatLoading = false;
      });
      print('Chat error: $e');
    }
  }

  void _showExtendedChat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Assistant IA MollySou",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _secondaryTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Messages
              Expanded(
                child: _buildChatMessages(),
              ),

              // Input
              _buildExtendedChatInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      reverse: false,
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] ?? false;
    final text = message['text'] ?? '';
    final isError = message['isError'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Color(0xFF6A11CB)
                    : (isError ? Colors.red.withOpacity(0.1) : _inputBackgroundColor),
                borderRadius: BorderRadius.circular(16),
                border: isError ? Border.all(color: Colors.red) : null,
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : (isError ? Colors.red : _textColor),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(userData["photoProfil"]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExtendedChatInput() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _inputBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: TextStyle(color: _textColor),
              decoration: InputDecoration(
                hintText: "Tapez votre message...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.white54 : Colors.grey[500]
                ),
              ),
              onChanged: (value) {
                _getChatSuggestions(value);
              },
              onSubmitted: (value) {
                _handleChatMessage(value);
              },
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _isChatLoading
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              )
                  : Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _isChatLoading ? null : () {
                _handleChatMessage(_chatController.text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
