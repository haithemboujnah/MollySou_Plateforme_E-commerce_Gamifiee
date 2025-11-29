import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mollysou/services/cart_service.dart';
import 'package:mollysou/services/product_service.dart';
import 'package:mollysou/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  final Map<String, dynamic> category;

  const ProductsByCategoryScreen({Key? key, required this.category}) : super(key: key);

  @override
  _ProductsByCategoryScreenState createState() => _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  List<dynamic> products = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadProducts();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _loadProducts() async {
    try {
      final categoryId = widget.category['id'];
      if (categoryId != null) {
        final productsData = await ProductService.getProductsByCategory(categoryId);
        setState(() {
          products = productsData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ID de catégorie invalide';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des produits';
        _isLoading = false;
      });
      print('Error loading products: $e');
    }
  }

  // Couleurs pour le mode sombre
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF8FAFC);
  Color get _appBarColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _priceColor => _isDarkMode ? Color(0xFF00FFAA) : Color(0xFF6A11CB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 1,
        title: Text(
          widget.category['nom'] ?? 'Produits',
          style: GoogleFonts.aBeeZee(
            color: _textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _buildProductsGrid(),
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
            'Chargement des produits...',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              color: _textColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A11CB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Réessayer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: _secondaryTextColor,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Revenez plus tard pour découvrir nos nouveaux produits',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7, // Reduced from 0.75 to 0.7
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _showProductDetails(products[index]);
            },
            child: _buildProductCard(products[index]),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = product['prix']?.toString() ?? '0.0';
    final rating = product['rating']?.toString() ?? '0.0';
    final stock = product['stock'] ?? 0;
    final isAvailable = product['disponible'] == true && stock > 0;

    return Card(
      elevation: 4,
      color: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Fixed height
            Container(
              height: 100, // Reduced from 120 to 100
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[100],
                image: product['image'] != null
                    ? DecorationImage(
                  image: NetworkImage(product['image']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: product['image'] == null
                  ? Center(
                child: Icon(
                  Icons.shopping_bag,
                  color: _secondaryTextColor,
                  size: 32, // Reduced from 40 to 32
                ),
              )
                  : null,
            ),

            // Product Info - Better spacing
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8), // Reduced from 12 to 8
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better distribution
                  children: [
                    // Product Name and Description in a column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product['nom'] ?? 'Produit sans nom',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12, // Reduced from 14 to 12
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2), // Reduced spacing

                        // Product Description - Only show if there's space
                        if (product['description'] != null)
                          Text(
                            product['description'],
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 10, // Reduced from 11 to 10
                              height: 1.1,
                            ),
                            maxLines: 1, // Reduced from 2 to 1
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),

                    // Rating and Stock
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12), // Reduced size
                        SizedBox(width: 2), // Reduced spacing
                        Text(
                          rating,
                          style: TextStyle(
                            color: _secondaryTextColor,
                            fontSize: 10, // Reduced from 12 to 10
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '$stock',
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontSize: 9, // Reduced from 11 to 9
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Price and Add to Cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$price DT',
                            style: TextStyle(
                              color: _priceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14, // Reduced from 16 to 14
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 28, // Reduced from 36 to 28
                          height: 28, // Reduced from 36 to 28
                          decoration: BoxDecoration(
                            color: isAvailable ? Color(0xFF6A11CB) : Colors.grey,
                            borderRadius: BorderRadius.circular(8), // Reduced from 10 to 8
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 14, // Reduced from 18 to 14
                            ),
                            onPressed: isAvailable
                                ? () {
                              _addToCart(product);
                            }
                                : null,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) async {
    // Get user ID
    final userResult = await UserService.getCurrentUser();
    if (userResult['success'] == true) {
      final userId = userResult['userId'];
      final productId = product['id'];

      try {
        final result = await CartService.addToCart(userId, productId, 1);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color(0xFF6A11CB),
              content: Text(
                '${product['nom']} ajouté au panier',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                result['error'] ?? 'Erreur lors de l\'ajout au panier',
                style: TextStyle(color: Colors.white),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Erreur de connexion',
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Veuillez vous connecter',
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showProductDetails(Map<String, dynamic> product) {
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
        return SingleChildScrollView( // Added SingleChildScrollView to prevent overflow
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Détails du produit',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _secondaryTextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Product Image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[100],
                    image: product['image'] != null
                        ? DecorationImage(
                      image: NetworkImage(product['image']),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: product['image'] == null
                      ? Center(
                    child: Icon(
                      Icons.shopping_bag,
                      color: _secondaryTextColor,
                      size: 60,
                    ),
                  )
                      : null,
                ),
                SizedBox(height: 20),

                // Product Name
                Text(
                  product['nom'] ?? 'Produit sans nom',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                // Description
                if (product['description'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['description'],
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 15),
                    ],
                  ),

                // Rating and Reviews
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text(
                      product['rating']?.toString() ?? '0.0',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(${product['nombreAvis'] ?? 0} avis)',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),

                // Stock Status
                Row(
                  children: [
                    Icon(
                      (product['disponible'] == true && (product['stock'] ?? 0) > 0)
                          ? Icons.check_circle : Icons.cancel,
                      color: (product['disponible'] == true && (product['stock'] ?? 0) > 0)
                          ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      (product['disponible'] == true && (product['stock'] ?? 0) > 0)
                          ? 'En stock (${product['stock']} disponibles)'
                          : 'Rupture de stock',
                      style: TextStyle(
                        color: (product['disponible'] == true && (product['stock'] ?? 0) > 0)
                            ? Colors.green : Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Price and Add to Cart Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product['prix']?.toString() ?? '0.0'} DT',
                      style: TextStyle(
                        color: _priceColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: (product['disponible'] == true && (product['stock'] ?? 0) > 0)
                          ? () {
                        _addToCart(product);
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6A11CB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Ajouter au panier',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10), // Extra space for keyboard
              ],
            ),
          ),
        );
      },
    );
  }
}