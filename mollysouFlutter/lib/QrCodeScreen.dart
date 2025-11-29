import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomeScreen.dart';

class QrCodeScreen extends StatefulWidget {
  final double totalAmount;
  final String orderNumber;
  final List<dynamic> cartItems;
  final double? discountAmount;
  final double? originalAmount;
  final String? userRank;
  final int pointsEarned; // Nouveau paramètre
  final int xpEarned; // Nouveau paramètre

  QrCodeScreen({
    required this.totalAmount,
    required this.orderNumber,
    required this.cartItems,
    this.discountAmount,
    this.originalAmount,
    this.userRank,
    this.pointsEarned = 0, // Valeur par défaut
    this.xpEarned = 0, // Valeur par défaut
  });

  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
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
  Color get _backgroundColor => _isDarkMode ? Color(0xFF1A1A2E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => _isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => _isDarkMode ? Color(0xFF16213E) : Colors.white;
  Color get _iconColor => _isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _discountColor => _isDarkMode ? Color(0xFF00FFAA) : Color(0xFF00A86B);
  Color get _rewardsColor => _isDarkMode ? Color(0xFFFFD700) : Color(0xFFFF6B00);

  // Get product details for QR data
  String get _qrData {
    final productNames = widget.cartItems
        .map((item) => '• ${item['productName'] ?? 'Produit'} x${item['quantity']}')
        .join('\n');

    // Ajouter les informations de discount si disponibles
    String discountInfo = '';
    if (widget.discountAmount != null && widget.discountAmount! > 0) {
      discountInfo = '\nDiscount: -${widget.discountAmount!.toStringAsFixed(2)} DT';
    }

    // Ajouter les récompenses si disponibles
    String rewardsInfo = '';
    if (widget.pointsEarned > 0 || widget.xpEarned > 0) {
      rewardsInfo = '\nRécompenses: +${widget.pointsEarned} pts, +${widget.xpEarned} XP';
    }

    return '''
COMMANDE MOLLYSOU
N°: ${widget.orderNumber}
Montant: ${widget.totalAmount.toStringAsFixed(2)} DT$discountInfo$rewardsInfo
Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}

PRODUITS:
$productNames

Merci pour votre achat !
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Icône de succès
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green, size: 40),
            ),
            SizedBox(height: 20),

            Text(
              'Paiement Réussi !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Votre commande a été confirmée',
              style: TextStyle(
                fontSize: 16,
                color: _secondaryTextColor,
              ),
            ),
            SizedBox(height: 30),

            // Carte de confirmation
            Card(
              color: _cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Votre QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Vrai QR Code
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: _isDarkMode ? Colors.white24 : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF6A11CB),
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Présentez ce code pour récupérer vos produits',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.orderNumber,
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Section des récompenses (si gagnées)
                    if (widget.pointsEarned > 0 || widget.xpEarned > 0)
                      _buildRewardsSection(),

                    // Détails de la commande
                    _buildOrderDetail('N° de commande', widget.orderNumber),
                    _buildOrderDetail('Montant total', '${widget.totalAmount.toStringAsFixed(2)} DT'),
                    _buildOrderDetail('Date', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())),
                    _buildOrderDetail('Nombre d\'articles', '${_getTotalItems()} produit(s)'),

                    // Afficher le discount si disponible
                    if (widget.discountAmount != null && widget.discountAmount! > 0)
                      _buildDiscountInfo(),

                    // Liste des produits achetés
                    SizedBox(height: 16),
                    _buildProductList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _shareQrCode,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Color(0xFF6A11CB)),
                    ),
                    child: _isSaving
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                      ),
                    )
                        : Text(
                      'Partager QR Code',
                      style: TextStyle(
                        color: Color(0xFF6A11CB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6A11CB),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Accueil',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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

  // NOUVELLE MÉTHODE : Section des récompenses
  Widget _buildRewardsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _rewardsColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rewardsColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.celebration, color: _rewardsColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Récompenses Gagnées !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rewardsColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (widget.pointsEarned > 0)
                _buildRewardItem(
                  'Points',
                  '+${widget.pointsEarned}',
                  Icons.emoji_events,
                  Color(0xFFFFD700),
                ),
              if (widget.xpEarned > 0)
                _buildRewardItem(
                  'XP',
                  '+${widget.xpEarned}',
                  Icons.trending_up,
                  Color(0xFF4ECDC4),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Ces récompenses ont été ajoutées à votre compte',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountInfo() {
    return Column(
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.discount, color: _discountColor, size: 16),
                SizedBox(width: 4),
                Text(
                  'Discount appliqué',
                  style: TextStyle(
                    color: _discountColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Text(
              '-${widget.discountAmount!.toStringAsFixed(2)} DT',
              style: TextStyle(
                color: _discountColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        if (widget.userRank != null) ...[
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Votre Rank',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              Text(
                widget.userRank!,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProductList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produits achetés:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _textColor,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        ...widget.cartItems.map((item) => _buildProductItem(item)).toList(),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final price = double.parse(item['price'].toString());
    final quantity = item['quantity'] ?? 1;
    final total = price * quantity;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF0F3460) : Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: item['productImage'] != null
                  ? Image.network(
                item['productImage'],
                width: 20,
                height: 20,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.shopping_bag, size: 16, color: _secondaryTextColor),
            ),
          ),
          SizedBox(width: 12),

          // Nom du produit
          Expanded(
            child: Text(
              item['productName'] ?? 'Produit sans nom',
              style: TextStyle(
                color: _textColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quantité et prix
          Text(
            'x$quantity',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${total.toStringAsFixed(2)} DT',
            style: TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalItems() {
    return widget.cartItems.fold<int>(
      0,
          (sum, item) {
        final q = item['quantity'];

        // Convertir en int correctement et toujours retourner int
        final quantity = q is int ? q : int.tryParse(q.toString()) ?? 1;

        return sum + quantity; // -> toujours int
      },
    );
  }


  Future<void> _shareQrCode() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Capturer le QR code
      final Uint8List pngBytes = await _captureQrCode();

      // Message détaillé avec instructions
      final productList = widget.cartItems
          .map((item) => '• ${item['productName'] ?? 'Produit'} x${item['quantity']} - ${double.parse(item['price'].toString()).toStringAsFixed(2)} DT')
          .join('\n');

      // Ajouter les informations de discount
      String discountInfo = '';
      if (widget.discountAmount != null && widget.discountAmount! > 0) {
        discountInfo = '\n🎁 Discount: -${widget.discountAmount!.toStringAsFixed(2)} DT';
        if (widget.userRank != null) {
          discountInfo += ' (Rank ${widget.userRank!})';
        }
      }

      // Ajouter les récompenses
      String rewardsInfo = '';
      if (widget.pointsEarned > 0 || widget.xpEarned > 0) {
        rewardsInfo = '\n🎉 Récompenses: +${widget.pointsEarned} points, +${widget.xpEarned} XP';
      }

      final String shareText = '''
🛍️ MA COMMANDE MOLLYSOU

✅ Paiement confirmé !
📋 Commande: ${widget.orderNumber}
💰 Montant total: ${widget.totalAmount.toStringAsFixed(2)} DT$discountInfo$rewardsInfo
📅 Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}

🛒 PRODUITS COMMANDÉS:
$productList

📍 INSTRUCTIONS:
1️⃣ Présentez ce QR code au vendeur
2️⃣ Il sera scanné pour validation
3️⃣ Récupérez vos produits

💡 CONSEILS:
• Faites une CAPTURE D'ÉCRAN pour sauvegarder
• Ou partagez vers GALERIE/GOOGLE DRIVE
• Ayez le QR code visible sur votre téléphone

Merci pour votre confiance ! 🎉
    ''';

      // Partager avec instructions claires
      await Share.share(
        shareText,
        subject: '🛍️ Ma Commande MollySou - ${widget.orderNumber}',
      );

      _showSuccessSnackbar(
          'QR code partagé !\n'
              '💡 Conseil: Faites une capture d\'écran\n'
              'pour sauvegarder votre reçu.'
      );

    } catch (e) {
      // Fallback simple
      await Share.share(
        'Ma commande MollySou - ${widget.orderNumber}\n'
            'Montant: ${widget.totalAmount.toStringAsFixed(2)} DT\n'
            'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n'
            'Le QR code est dans l\'application.',
      );
      _showSuccessSnackbar('Détails de la commande partagés !');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Capturer le QR code
  Future<Uint8List> _captureQrCode() async {
    try {
      final RenderRepaintBoundary boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      // Retourner une image vide en cas d'erreur
      return Uint8List(0);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 5),
      ),
    );
  }
}