// Replace the entire CartScreen.dart with this dynamic version
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/user_service.dart';
import 'services/cart_service.dart';
import 'PaymentScreen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndCart();
  }

  Future<void> _loadUserAndCart() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });

    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      setState(() {
        _userId = userResult['userId'];
      });
      await _loadCartItems();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCartItems() async {
    if (_userId == null) return;

    try {
      final cartData = await CartService.getUserCart(_userId!);
      setState(() {
        cartItems = cartData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _appBarColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _iconColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);

  double get totalPrice {
    return cartItems.fold(0, (sum, item) => sum + (double.parse(item['price'].toString()) * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Mon Panier', style: TextStyle(color: _textColor)),
        backgroundColor: _appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _userId == null
          ? _buildLoginRequired()
          : Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartItems(),
          ),
          _buildTotalSection(),
        ],
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
            'Chargement du panier...',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: _secondaryTextColor),
          SizedBox(height: 16),
          Text(
            'Connexion requise',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Veuillez vous connecter pour accéder à votre panier',
            style: TextStyle(color: _secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_cart, size: 50, color: _isDarkMode ? Colors.white70 : Colors.grey[400]),
          ),
          SizedBox(height: 20),
          Text(
            'Panier vide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Ajoutez des produits à votre panier',
            style: TextStyle(color: _secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final cartItem = cartItems[index];
        return _buildCartItem(cartItem, index);
      },
    );
  }

  Widget _buildCartItem(Map<String, dynamic> cartItem, int index) {
    final price = double.parse(cartItem['price'].toString());
    final stock = cartItem['stock'] ?? 0;
    final isAvailable = stock > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: cartItem['productImage'] != null
                    ? Image.network(
                  cartItem['productImage'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                )
                    : Icon(Icons.shopping_bag, color: _secondaryTextColor),
              ),
            ),
            SizedBox(width: 16),

            // Détails du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem['productName'] ?? 'Produit sans nom',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    cartItem['category'] ?? 'Catégorie',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${price.toStringAsFixed(2)}DT',
                    style: TextStyle(
                      color: Color(0xFF6A11CB),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (!isAvailable)
                    Text(
                      'Stock épuisé',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Contrôle quantité et suppression
            Column(
              children: [
                // Bouton supprimer
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
                  onPressed: () {
                    _removeFromCart(cartItem['productId']);
                  },
                ),
                SizedBox(height: 8),

                // Contrôle quantité
                Container(
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 18, color: _textColor),
                        onPressed: () {
                          final currentQuantity = cartItem['quantity'];
                          if (currentQuantity > 1) {
                            _updateCartItem(cartItem['productId'], currentQuantity - 1);
                          }
                        },
                      ),
                      Text(
                        cartItem['quantity'].toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 18, color: _textColor),
                        onPressed: () {
                          final currentQuantity = cartItem['quantity'];
                          if (currentQuantity < stock) {
                            _updateCartItem(cartItem['productId'], currentQuantity + 1);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stock insuffisant'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(_isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(2)}DT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A11CB),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cartItems.isNotEmpty ? _proceedToPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A11CB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: Text(
                'Procéder au paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCartItem(int productId, int quantity) async {
    if (_userId == null) return;

    try {
      final result = await CartService.updateCartItem(_userId!, productId, quantity);
      if (result['success'] == true) {
        await _loadCartItems(); // Reload cart
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur de mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromCart(int productId) async {
    if (_userId == null) return;

    try {
      final result = await CartService.removeFromCart(_userId!, productId);
      if (result['success'] == true) {
        await _loadCartItems(); // Reload cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit supprimé du panier'),
            backgroundColor: Color(0xFF6A11CB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur de suppression'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(totalAmount: totalPrice, cartItems: cartItems),
      ),
    );
  }
}