import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mollysou/services/points_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'QrCodeScreen.dart';
import 'services/user_service.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<dynamic> cartItems;

  PaymentScreen({
    required this.totalAmount,
    required this.cartItems,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isProcessing = false;
  bool _isDarkMode = false;

  // Variables pour le discount
  Map<String, dynamic>? _currentUser;
  double _discountPercentage = 0.0;
  double _discountAmount = 0.0;
  double _finalAmount = 0.0;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await UserService.getCurrentUser();
      if (result['success'] == true) {
        setState(() {
          _currentUser = result['user'];
          _calculateDiscount();
          _isLoadingUser = false;
        });
      } else {
        setState(() {
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  void _calculateDiscount() {
    if (_currentUser != null) {
      String userRank = _currentUser!['rank'] ?? 'BRONZE';

      // Déterminer le pourcentage de discount selon le rank
      switch (userRank.toUpperCase()) {
        case 'DIAMOND':
          _discountPercentage = 50.0;
          break;
        case 'PLATINUM':
          _discountPercentage = 20.0;
          break;
        case 'GOLD':
          _discountPercentage = 15.0;
          break;
        case 'SILVER':
          _discountPercentage = 10.0;
          break;
        case 'BRONZE':
          _discountPercentage = 5.0;
          break;
        default:
          _discountPercentage = 0.0;
      }

      // Calculer le montant du discount
      double subtotal = widget.totalAmount;
      _discountAmount = (subtotal * _discountPercentage) / 100;

      // Calculer le montant final
      double serviceFee = 2.50;
      _finalAmount = (subtotal - _discountAmount) + serviceFee;
    } else {
      // Si pas d'utilisateur, pas de discount
      double serviceFee = 2.50;
      _finalAmount = widget.totalAmount + serviceFee;
    }
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _appBarColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _iconColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _inputBackgroundColor => _isDarkMode ? Color(0xFF0F3460) : Colors.grey[50]!;
  Color get _discountColor => _isDarkMode ? Color(0xFF00FFAA) : Color(0xFF00A86B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Paiement', style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingUser
          ? _buildLoadingState()
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de rank et discount
            _buildRankBadge(),
            SizedBox(height: 20),

            // Résumé de commande
            _buildOrderSummary(),
            SizedBox(height: 30),

            // Détails des articles
            _buildCartItems(),
            SizedBox(height: 30),

            // Formulaire de paiement
            _buildPaymentForm(),
            SizedBox(height: 30),

            // Bouton de paiement
            _buildPayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des informations...',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    if (_currentUser == null) return SizedBox();

    String userRank = _currentUser!['rank'] ?? 'BRONZE';
    String rankName = _getRankName(userRank);
    Color rankColor = _getRankColor(userRank);

    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Badge du rank
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getRankGradient(userRank),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre Rank: $rankName',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Discount: $_discountPercentage%',
                    style: TextStyle(
                      fontSize: 14,
                      color: _discountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Économie: ${_discountAmount.toStringAsFixed(2)} DT',
                    style: TextStyle(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    double serviceFee = 2.50;
    double subtotal = widget.totalAmount;

    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de commande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 16),

            // Sous-total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total', style: TextStyle(color: _secondaryTextColor)),
                Text('${subtotal.toStringAsFixed(2)} DT', style: TextStyle(color: _textColor)),
              ],
            ),
            SizedBox(height: 8),

            // Discount
            if (_discountAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.discount, color: _discountColor, size: 16),
                      SizedBox(width: 4),
                      Text('Discount ($_discountPercentage%)',
                          style: TextStyle(color: _discountColor)),
                    ],
                  ),
                  Text(
                    '-${_discountAmount.toStringAsFixed(2)} DT',
                    style: TextStyle(
                      color: _discountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],

            // Frais de service
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Frais de service', style: TextStyle(color: _secondaryTextColor)),
                Text('${serviceFee.toStringAsFixed(2)} DT', style: TextStyle(color: _textColor)),
              ],
            ),
            SizedBox(height: 12),

            Divider(color: _isDarkMode ? Colors.white24 : Colors.grey[300]),
            SizedBox(height: 8),

            // Total final
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_discountAmount > 0)
                      Text(
                        '${(subtotal + serviceFee).toStringAsFixed(2)} DT',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text(
                      '${_finalAmount.toStringAsFixed(2)} DT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A11CB),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Économie totale
            if (_discountAmount > 0) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _discountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _discountColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings, color: _discountColor, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Vous économisez ${_discountAmount.toStringAsFixed(2)} DT',
                      style: TextStyle(
                        color: _discountColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Articles dans votre panier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 12),
            ...widget.cartItems.map((item) => _buildCartItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final price = double.parse(item['price'].toString());
    final quantity = item['quantity'] ?? 1;
    final total = price * quantity;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: item['productImage'] != null
                  ? Image.network(
                item['productImage'],
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.shopping_bag, size: 20, color: _secondaryTextColor),
            ),
          ),
          SizedBox(width: 12),

          // Détails du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Produit sans nom',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${price.toStringAsFixed(2)}DT × $quantity',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Prix total pour cet article
          Text(
            '${total.toStringAsFixed(2)} DT',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 20),

            // Numéro de carte
            _buildFormField(
              label: 'Numéro de carte',
              hintText: '1234 5678 9012 3456',
              controller: _cardNumberController,
              icon: Icons.credit_card,
            ),
            SizedBox(height: 16),

            _buildFormField(
              label: 'Nom sur la carte',
              hintText: 'Mr. X',
              controller: _nameController,
              icon: Icons.person,
            ),
            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    label: 'Date d\'expiration',
                    hintText: 'MM/AA',
                    controller: _expiryController,
                    icon: Icons.calendar_today,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildFormField(
                    label: 'CVV',
                    hintText: '123',
                    controller: _cvvController,
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: _secondaryTextColor),
            prefixIcon: Icon(icon, color: Color(0xFF6A11CB)),
            filled: true,
            fillColor: _inputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6A11CB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
        child: _isProcessing
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Payer ${_finalAmount.toStringAsFixed(2)} DT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _processPayment() async {
    // Validation simple
    if (_cardNumberController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      _showErrorSnackbar('Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Récupérer l'ID utilisateur
      final userResult = await UserService.getCurrentUser();
      if (userResult['success'] != true) {
        throw Exception('Utilisateur non connecté');
      }

      final userId = userResult['userId'];

      // Simulation de traitement de paiement
      await Future.delayed(Duration(seconds: 2));

      // Ajouter les récompenses (points + XP) pour l'achat
      final rewardsResult = await PointsService.addPurchaseXP(
        userId: userId,
        purchaseAmount: _finalAmount,
      );

      if (rewardsResult['success'] == true) {
        print('✅ Purchase rewards added successfully');
        print('📊 Points added: ${rewardsResult['pointsAdded']}');
        print('📈 XP added: ${rewardsResult['xpAdded']}');

        // FORCE SYNC USER DATA TO UPDATE LOCAL STORAGE
        final syncResult = await UserService.syncUserDataFromDatabase();
        if (syncResult['success'] == true) {
          print('🔄 User data synced after purchase');
        }

        // Afficher les récompenses gagnées
        _showPurchaseRewardsDialog(
          rewardsResult['pointsAdded'] ?? 0,
          rewardsResult['xpAdded'] ?? 0,
        );

        // Naviguer vers l'écran QR Code
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeScreen(
              totalAmount: _finalAmount,
              discountAmount: _discountAmount,
              originalAmount: widget.totalAmount + 2.50,
              orderNumber: 'CMD-${DateTime.now().millisecondsSinceEpoch}',
              cartItems: widget.cartItems,
              userRank: _currentUser?['rank'] ?? 'BRONZE',
              pointsEarned: rewardsResult['pointsAdded'] ?? 0,
              xpEarned: rewardsResult['xpAdded'] ?? 0,
            ),
          ),
        );
      } else {
        print('❌ Failed to add purchase rewards: ${rewardsResult['error']}');

        // Sync user data anyway to ensure consistency
        await UserService.syncUserDataFromDatabase();

        _showWarningSnackbar('Paiement réussi mais récompenses non ajoutées');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeScreen(
              totalAmount: _finalAmount,
              discountAmount: _discountAmount,
              originalAmount: widget.totalAmount + 2.50,
              orderNumber: 'CMD-${DateTime.now().millisecondsSinceEpoch}',
              cartItems: widget.cartItems,
              userRank: _currentUser?['rank'] ?? 'BRONZE',
              pointsEarned: 0,
              xpEarned: 0,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Payment processing error: $e');
      _showErrorSnackbar('Erreur lors du traitement du paiement');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPurchaseRewardsDialog(int pointsEarned, int xpEarned) {
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
              child: Icon(Icons.celebration, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Récompenses Gagnées !',
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
            Text(
              'Merci pour votre achat !',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),

            // Points gagnés
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
                    '+$pointsEarned Points',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // XP gagné
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
                    '+$xpEarned XP',
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
              'Continuez vos achats pour gagner plus de récompenses !',
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

  void _showWarningSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Méthodes utilitaires pour les ranks
  String _getRankName(String rank) {
    switch (rank.toUpperCase()) {
      case 'DIAMOND': return 'DIAMANT';
      case 'PLATINUM': return 'PLATINE';
      case 'GOLD': return 'OR';
      case 'SILVER': return 'ARGENT';
      case 'BRONZE': return 'BRONZE';
      default: return rank;
    }
  }

  Color _getRankColor(String rank) {
    switch (rank.toUpperCase()) {
      case 'DIAMOND': return Color(0xFF1E3A8A);
      case 'PLATINUM': return Color(0xFF0BC5EA);
      case 'GOLD': return Color(0xFFFFD700);
      case 'SILVER': return Color(0xFFC0C0C0);
      case 'BRONZE': return Color(0xFFCD7F32);
      default: return Color(0xFF6A11CB);
    }
  }

  List<Color> _getRankGradient(String rank) {
    switch (rank.toUpperCase()) {
      case 'DIAMOND': return [Color(0xFF1E3A8A), Color(0xFF3B82F6)];
      case 'PLATINUM': return [Color(0xFF06B6D4), Color(0xFF0BC5EA)];
      case 'GOLD': return [Color(0xFFFFF8DC), Color(0xFFFFD700)];
      case 'SILVER': return [Color(0xFFF0F0F0), Color(0xFFC0C0C0)];
      case 'BRONZE': return [Color(0xFFDEB887), Color(0xFFCD7F32)];
      default: return [Color(0xFF6A11CB), Color(0xFF2575FC)];
    }
  }
}