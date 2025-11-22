import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'PaymentScreen.dart';
import 'Product.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Product> cartItems = [
    Product(
      id: '1',
      name: 'Concert Rock Festival',
      price: 45.00,
      image: '🎵',
      category: 'Concerts',
    ),
    Product(
      id: '2',
      name: 'Match de Football',
      price: 35.00,
      image: '⚽',
      category: 'Sports',
    ),
    Product(
      id: '3',
      name: 'Comédie Musicale',
      price: 60.00,
      image: '🎭',
      category: 'Théâtre',
    ),
  ];

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

  double get totalPrice {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
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
      body: Column(
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
        final product = cartItems[index];
        return _buildCartItem(product, index);
      },
    );
  }

  Widget _buildCartItem(Product product, int index) {
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
                child: Text(
                  product.image,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(width: 16),

            // Détails du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
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
                    product.category,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(2)}€',
                    style: TextStyle(
                      color: Color(0xFF6A11CB),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                    setState(() {
                      cartItems.removeAt(index);
                    });
                    _showDeleteSnackbar(product.name);
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
                          if (product.quantity > 1) {
                            setState(() {
                              product.quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        product.quantity.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _textColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 18, color: _textColor),
                        onPressed: () {
                          setState(() {
                            product.quantity++;
                          });
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
                '${totalPrice.toStringAsFixed(2)}€',
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
              onPressed: () {
                if (cartItems.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(totalAmount: totalPrice),
                    ),
                  );
                }
              },
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

  void _showDeleteSnackbar(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName supprimé du panier'),
        backgroundColor: Color(0xFF6A11CB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}