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

  QrCodeScreen({required this.totalAmount, required this.orderNumber});

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

  String get _qrData {
    return '''
Commande: ${widget.orderNumber}
Montant: ${widget.totalAmount.toStringAsFixed(2)}€
Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}
Événement: Concert Rock Festival
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
                              'Scannez ce code à l\'entrée',
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

                    // Détails de la commande
                    _buildOrderDetail('N° de commande', widget.orderNumber),
                    _buildOrderDetail('Montant total', '${widget.totalAmount.toStringAsFixed(2)}€'),
                    _buildOrderDetail('Date', DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())),
                    _buildOrderDetail('Événement', 'Concert Rock Festival'),
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

  Future<void> _shareQrCode() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Capturer le QR code
      final Uint8List pngBytes = await _captureQrCode();

      // Message détaillé avec instructions
      final String shareText = '''
🎫 MON TICKET ÉVÉNEMENT

✅ Paiement confirmé !
📋 Commande: ${widget.orderNumber}
💰 Montant: ${widget.totalAmount.toStringAsFixed(2)}€
📅 Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}
🎸 Événement: Concert Rock Festival

📍 INSTRUCTIONS:
1️⃣ Présentez ce QR code à l'entrée
2️⃣ Il sera scanné pour validation
3️⃣ Gardez-le jusqu'à la fin de l'événement

💡 CONSEILS:
• Faites une CAPTURE D'ÉCRAN pour sauvegarder
• Ou partagez vers GALERIE/GOOGLE DRIVE
• Ayez le QR code visible sur votre téléphone
    ''';

      // Partager avec instructions claires
      await Share.share(
        shareText,
        subject: '🎫 Mon Ticket - Commande ${widget.orderNumber}',
      );

      _showSuccessSnackbar(
          'QR code partagé !\n'
              '💡 Conseil: Faites une capture d\'écran\n'
              'ou sauvegardez dans votre galerie.'
      );

    } catch (e) {
      // Fallback simple
      await Share.share(
        'Mon ticket - Commande ${widget.orderNumber}\n'
            'Montant: ${widget.totalAmount.toStringAsFixed(2)}€\n'
            'Événement: Concert Rock Festival\n\n'
            'Le QR code est dans l\'application.',
      );
      _showSuccessSnackbar('Détails du ticket partagés !');
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