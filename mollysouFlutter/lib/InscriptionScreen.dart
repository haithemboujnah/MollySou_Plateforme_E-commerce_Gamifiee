import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_service.dart'; // Add this import
import 'HomeScreen.dart';
import 'LoginScreen.dart';

class InscriptionScreen extends StatefulWidget {
  @override
  _InscriptionScreenState createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGenre;
  bool _isLoading = false;
  bool _isDarkMode = false;

  // Variables pour la visibilité des mots de passe
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Variables pour gérer les erreurs
  bool _hasValidationError = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

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

    // Écouter les changements dans les champs pour effacer les erreurs
    _setupErrorListeners();
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

  void _setupErrorListeners() {
    _nomController.addListener(_clearErrors);
    _emailController.addListener(_clearErrors);
    _passwordController.addListener(_clearErrors);
    _confirmPasswordController.addListener(_clearErrors);
  }

  void _clearErrors() {
    if (_hasValidationError) {
      setState(() {
        _hasValidationError = false;
      });
      // Force la revalidation pour effacer les messages d'erreur
      _formKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomController.removeListener(_clearErrors);
    _emailController.removeListener(_clearErrors);
    _passwordController.removeListener(_clearErrors);
    _confirmPasswordController.removeListener(_clearErrors);
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
                  // Header avec flèche de retour
                  SizedBox(height: 40),
                  _buildBackButton(),
                  SizedBox(height: 20),

                  // Logo
                  _buildLogo(),
                  SizedBox(height: 20),

                  // Titre principal
                  _buildTitle(),
                  SizedBox(height: 40),

                  // Section d'inscription
                  _buildInscriptionSection(),
                  SizedBox(height: 30),

                  // Bouton d'inscription
                  _buildInscriptionButton(),
                  SizedBox(height: 25),

                  // Lien vers connexion
                  _buildLoginLink(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFF6A11CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6A11CB).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: Icon(Icons.person_add, color: Colors.white, size: 40),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          "Rejoignez MollySou",
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
          "Créez votre compte pour profiter de tous nos avantages",
          style: GoogleFonts.aBeeZee(
            fontSize: 16,
            color: _secondaryTextColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInscriptionSection() {
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildGamifiedTextField(
                icon: Icons.person_outline,
                hintText: "Nom complet",
                isPassword: false,
                controller: _nomController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Ce champ est obligatoire";
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildGamifiedTextField(
                icon: Icons.email_outlined,
                hintText: "Adresse email",
                isPassword: false,
                controller: _emailController,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Email requis";
                  if (!value!.contains('@')) return "Email invalide";
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildGenreDropdown(),
              SizedBox(height: 20),
              _buildGamifiedTextField(
                icon: Icons.lock_outline,
                hintText: "Mot de passe",
                isPassword: true,
                controller: _passwordController,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: _togglePasswordVisibility,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Mot de passe requis";
                  if (value!.length < 6) return "6 caractères minimum";
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildGamifiedTextField(
                icon: Icons.lock_outline,
                hintText: "Confirmer le mot de passe",
                isPassword: true,
                controller: _confirmPasswordController,
                isPasswordVisible: _isConfirmPasswordVisible,
                onToggleVisibility: _toggleConfirmPasswordVisibility,
                validator: (value) {
                  if (value?.isEmpty ?? true) return "Confirmation requise";
                  if (value != _passwordController.text) return "Les mots de passe ne correspondent pas";
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamifiedTextField({
    required IconData icon,
    required String hintText,
    required bool isPassword,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
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
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: TextStyle(color: _textColor),
        validator: validator,
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
              isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF6A11CB),
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          errorStyle: TextStyle(color: Color(0xFFFF6B6B)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreDropdown() {
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
      child: DropdownButtonFormField<String>(
        value: _selectedGenre,
        dropdownColor: _cardColor,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          hintText: "Genre",
          hintStyle: TextStyle(color: _hintTextColor),
          prefixIcon: Icon(Icons.person, color: Color(0xFF6A11CB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          errorStyle: TextStyle(color: Color(0xFFFF6B6B)),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFFFF6B6B), width: 1),
          ),
        ),
        items: ["Homme", "Femme", "Autre"]
            .map((genre) => DropdownMenuItem(
          value: genre,
          child: Text(genre, style: TextStyle(color: _textColor)),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedGenre = value;
            _clearErrors();
          });
        },
        validator: (value) {
          if (value == null) return "Veuillez sélectionner un genre";
          return null;
        },
      ),
    );
  }

  Widget _buildInscriptionButton() {
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
      onPressed: _handleInscription,
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
            colors: [Color(0xFFFF6B6B), Color(0xFF6A11CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6A11CB).withOpacity(0.4),
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
                "S'INSCRIRE",
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
          colors: [Color(0xFFFF6B6B).withOpacity(0.7), Color(0xFF6A11CB).withOpacity(0.7)],
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Déjà un compte ? ",
          style: TextStyle(color: _secondaryTextColor),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: Text(
            "Se connecter",
            style: TextStyle(
              color: Color(0xFF00FFAA),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _handleInscription() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _hasValidationError = false;
      });

      try {
        final result = await UserService.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nomController.text.trim(),
          _selectedGenre ?? 'Autre',
        );

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(result['error'] ?? "Erreur lors de l'inscription");
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Erreur de connexion au serveur");
      }
    } else {
      setState(() {
        _hasValidationError = true;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFF6A11CB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: Colors.white, size: 60),
              SizedBox(height: 20),
              Text(
                "Compte créé avec succès !",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Bienvenue dans la communauté MollySou",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  "Explorer MollySou",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
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
              backgroundColor: Color(0xFFFF6B6B),
            ),
            child: Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}