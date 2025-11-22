// Update PaymentScreen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'QrCodeScreen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<dynamic> cartItems; // Add this parameter

  PaymentScreen({
    required this.totalAmount,
    required this.cartItems, // Add this parameter
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

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildOrderSummary() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total', style: TextStyle(color: _secondaryTextColor)),
                Text('${widget.totalAmount.toStringAsFixed(2)}€', style: TextStyle(color: _textColor)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Frais de service', style: TextStyle(color: _secondaryTextColor)),
                Text('2.50€', style: TextStyle(color: _textColor)),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: _isDarkMode ? Colors.white24 : Colors.grey[300]),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                Text(
                  '${(widget.totalAmount + 2.50).toStringAsFixed(2)}€',
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
                  '${price.toStringAsFixed(2)}€ × $quantity',
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
            '${total.toStringAsFixed(2)}€',
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

            // Nom sur la carte
            _buildFormField(
              label: 'Nom sur la carte',
              hintText: 'John Doe',
              controller: _nameController,
              icon: Icons.person,
            ),
            SizedBox(height: 16),

            // Date d'expiration et CVV
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
          'Payer ${(widget.totalAmount + 2.50).toStringAsFixed(2)}€',
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

    // Simulation de traitement de paiement
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    // Générer le QR code et aller à l'écran de confirmation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QrCodeScreen(
          totalAmount: widget.totalAmount + 2.50,
          orderNumber: 'CMD-${DateTime.now().millisecondsSinceEpoch}',
          cartItems: widget.cartItems, // Pass cart items to QR code screen
        ),
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
}