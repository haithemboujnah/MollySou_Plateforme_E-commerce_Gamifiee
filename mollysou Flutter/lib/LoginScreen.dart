import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_service.dart'; // Add this import
import 'HomeScreen.dart';
import 'InscriptionScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _GamifiedLoginScreenState createState() => _GamifiedLoginScreenState();
}

class _GamifiedLoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isDarkMode = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _loadDarkModePreference();
    _checkExistingUser(); // Check if user is already logged in
  }

  // Check if user is already logged in
  Future<void> _checkExistingUser() async {
    final result = await UserService.getCurrentUser();
    if (result['success'] == true) {
      // User is already logged in, redirect to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
    }
  }

  // Charger la préférence du mode sombre
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _inputBackgroundColor => _isDarkMode ? Color(0xFF0F3460) : Colors.grey[50]!;
  Color get _inputBorderColor => _isDarkMode ? Colors.blue.withOpacity(0.3) : Colors.blue.withOpacity(0.5);
  Color get _hintTextColor => _isDarkMode ? Colors.white54 : Colors.grey[500]!;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header avec logo du mall
                  SizedBox(height: 80),
                  _buildLogo(),
                  SizedBox(height: 30),

                  // Titre principal
                  _buildTitle(),
                  SizedBox(height: 40),

                  // Section de connexion
                  _buildLoginSection(),
                  SizedBox(height: 30),

                  // Bouton de connexion
                  _buildLoginButton(),
                  SizedBox(height: 25),

                  // Options supplémentaires
                  _buildAdditionalOptions(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2575FC).withOpacity(0.4),
            blurRadius: 25,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Icon(Icons.shopping_bag, color: Colors.white, size: 50),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          "Bienvenue au MollySou",
          textAlign: TextAlign.center,
          style: GoogleFonts.aBeeZee(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: _textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Connectez-vous pour découvrir nos avantages",
          style: GoogleFonts.aBeeZee(
            fontSize: 16,
            color: _secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGamifiedTextField(
              icon: Icons.email_outlined,
              hintText: "Adresse email",
              isPassword: false,
              controller: _emailController,
            ),
            SizedBox(height: 20),
            _buildGamifiedTextField(
              icon: Icons.lock_outline,
              hintText: "Mot de passe",
              isPassword: true,
              controller: _passwordController,
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _showForgotPasswordDialog();
                  },
                  child: Text(
                    "Mot de passe oublié ?",
                    style: TextStyle(
                      color: Color(0xFF00FFAA),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildGamifiedTextField({
    required IconData icon,
    required String hintText,
    required bool isPassword,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: _isDarkMode
            ? LinearGradient(
          colors: [Color(0xFF0F3460).withOpacity(0.8), Color(0xFF1A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: _isDarkMode ? null : Colors.white,
        border: Border.all(color: _inputBorderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_passwordVisible : false,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _hintTextColor),
          prefixIcon: Icon(icon, color: Color(0xFF6A11CB)),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Color(0xFF6A11CB),
            ),
            onPressed: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          )
              : null,

        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: _isLoading
          ? _buildLoadingButton()
          : _buildActiveButton(),
    );
  }

  Widget _buildActiveButton() {
    return ElevatedButton(
      onPressed: _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00FFAA), Color(0xFF00CCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF00FFAA).withOpacity(0.4),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "SE CONNECTER",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00FFAA).withOpacity(0.7), Color(0xFF00CCFF).withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Nouveau membre ? ",
              style: TextStyle(color: _secondaryTextColor),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => InscriptionScreen()));
              },
              child: Text(
                "Créer un compte",
                style: TextStyle(
                  color: Color(0xFF00FFAA),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Veuillez remplir tous les champs");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        _showErrorDialog(result['error'] ?? "Erreur de connexion");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Erreur de connexion au serveur");
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Mot de passe oublié",
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Entrez votre email pour réinitialiser votre mot de passe",
          style: TextStyle(color: _secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog(message: "Email de réinitialisation envoyé !");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00FFAA),
            ),
            child: Text("Envoyer", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Erreur",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: _secondaryTextColor)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00FFAA),
            ),
            child: Text("OK", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({String message = "Connexion réussie !"}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00FFAA), Color(0xFF00CCFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 60),
              SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Continuer",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}