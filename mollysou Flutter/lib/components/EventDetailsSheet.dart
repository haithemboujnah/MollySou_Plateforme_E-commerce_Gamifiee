// lib/components/EventDetailsSheet.dart
import 'package:flutter/material.dart';

class EventDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  final bool isDarkMode;

  const EventDetailsSheet({
    Key? key,
    required this.event,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends State<EventDetailsSheet> {
  bool _isBooking = false;
  int _selectedTickets = 1;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Color(0xFF2D3748);
    final secondaryTextColor = widget.isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final cardColor = widget.isDarkMode ? Color(0xFF16213E) : Colors.white;
    final backgroundColor = widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[50];

    // Convertir le prix en numérique
    final prixUnitaire = _convertPriceToNumber(widget.event['prix']);
    final totalPrice = prixUnitaire * _selectedTickets;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec bouton fermer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Détails de l'événement",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Image de l'événement
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.event['image'] ?? '🎉',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Badge type d'événement
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEventTypeColor(widget.event['type']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.event['type'] ?? 'ÉVÉNEMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Badge note
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 4),
                      Text(
                        '${widget.event['rating'] ?? '0.0'}',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Titre
            Text(
              widget.event['titre'] ?? 'Événement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
            ),
            SizedBox(height: 12),

            // Description
            if (widget.event['description'] != null)
              Text(
                widget.event['description'],
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
              ),
            SizedBox(height: 20),

            // Section informations
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.location_on,
                    "Lieu",
                    widget.event['lieu'] ?? 'Non spécifié',
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildInfoRow(
                    Icons.calendar_today,
                    "Date",
                    _formatDetailedDate(widget.event['date']),
                    textColor,
                    secondaryTextColor,
                  ),
                  _buildInfoRow(
                    Icons.attach_money,
                    "Prix unitaire",
                    '${prixUnitaire.toStringAsFixed(2)} DT',
                    textColor,
                    secondaryTextColor,
                  ),
                  if (widget.event['places_disponibles'] != null)
                    _buildInfoRow(
                      Icons.people,
                      "Places disponibles",
                      '${widget.event['places_disponibles']}',
                      textColor,
                      secondaryTextColor,
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Sélection du nombre de tickets
            if (widget.event['places_disponibles'] != null && widget.event['places_disponibles'] > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nombre de tickets",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tickets",
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            // Bouton moins
                            Container(
                              decoration: BoxDecoration(
                                color: _selectedTickets > 1 ? Color(0xFF6A11CB) : Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.remove, color: Colors.white, size: 18),
                                onPressed: _selectedTickets > 1 ? () {
                                  setState(() {
                                    _selectedTickets--;
                                  });
                                } : null,
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              '$_selectedTickets',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            SizedBox(width: 16),
                            // Bouton plus
                            Container(
                              decoration: BoxDecoration(
                                color: _selectedTickets < (widget.event['places_disponibles'] ?? 1)
                                    ? Color(0xFF6A11CB)
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.add, color: Colors.white, size: 18),
                                onPressed: _selectedTickets < (widget.event['places_disponibles'] ?? 1) ? () {
                                  setState(() {
                                    _selectedTickets++;
                                  });
                                } : null,
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Places restantes: ${widget.event['places_disponibles']}",
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 20),

            // Prix total - CORRIGÉ ICI
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF6A11CB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total à payer",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${totalPrice.toStringAsFixed(2)} DT', // CORRECTION : Utilisation de la variable calculée
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A11CB),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Bouton de réservation
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6A11CB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _isBooking
                  ? Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
                  : TextButton(
                onPressed: _handleBooking,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Réserver maintenant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),

            // Bouton secondaire
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF6A11CB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Retour",
                  style: TextStyle(
                    color: Color(0xFF6A11CB),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  // Méthode pour convertir le prix en numérique
  double _convertPriceToNumber(dynamic price) {
    if (price == null) return 0.0;

    if (price is num) {
      return price.toDouble();
    }

    if (price is String) {
      // Nettoyer la chaîne (enlever "DT", espaces, etc.)
      String cleanedPrice = price.replaceAll('DT', '').trim();
      cleanedPrice = cleanedPrice.replaceAll(' ', '');

      // Remplacer la virgule par un point si nécessaire
      cleanedPrice = cleanedPrice.replaceAll(',', '.');

      try {
        return double.parse(cleanedPrice);
      } catch (e) {
        print('Erreur de conversion du prix: $e');
        return 0.0;
      }
    }

    return 0.0;
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Color(0xFF6A11CB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Color(0xFF6A11CB)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _formatDetailedDate(String? dateString) {
    if (dateString == null) return 'Date inconnue';

    try {
      // Gérer le format "Thu, 11 Dec 2025 00:00:00 GMT"
      DateTime date;
      if (dateString.contains(',')) {
        // Extraire la partie date: "11 Dec 2025"
        final regex = RegExp(r',\s*(\d+)\s+(\w+)\s+(\d+)');
        final match = regex.firstMatch(dateString);

        if (match != null) {
          final day = int.parse(match.group(1)!);
          final monthAbbr = match.group(2)!;
          final year = int.parse(match.group(3)!);

          final month = _getMonthNumber(monthAbbr);
          date = DateTime(year, month, day);
        } else {
          return 'Date invalide';
        }
      } else {
        // Format standard
        date = DateTime.parse(dateString);
      }

      final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

      return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Date invalide';
    }
  }

  int _getMonthNumber(String monthAbbr) {
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
    };
    return months[monthAbbr] ?? 1;
  }

  void _handleBooking() async {
    final placesDisponibles = widget.event['places_disponibles'] ?? 0;
    if (_selectedTickets > placesDisponibles) {
      _showErrorDialog("Nombre de tickets indisponible");
      return;
    }

    setState(() {
      _isBooking = true;
    });

    // Simulation du processus de réservation
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isBooking = false;
    });

    _showBookingConfirmation();
  }

  void _showBookingConfirmation() {
    final prixUnitaire = _convertPriceToNumber(widget.event['prix']);
    final totalPrice = prixUnitaire * _selectedTickets;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Color(0xFF16213E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 10),
            Text(
              "Réservation confirmée !",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event['titre'] ?? 'Événement',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${widget.event['lieu'] ?? 'Lieu inconnu'} • ${_formatDetailedDate(widget.event['date'])}',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]!,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nombre de tickets:",
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]!,
                  ),
                ),
                Text(
                  '$_selectedTickets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Prix unitaire:",
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]!,
                  ),
                ),
                Text(
                  '${prixUnitaire.toStringAsFixed(2)} DT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total payé:",
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]!,
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(2)} DT', // CORRECTION ICI AUSSI
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer la dialog
              Navigator.pop(context); // Fermer le bottom sheet
            },
            child: Text(
              "Fermer",
              style: TextStyle(color: Color(0xFF6A11CB)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? Color(0xFF16213E) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Erreur",
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.grey[600]!,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: Color(0xFF6A11CB)),
            ),
          ),
        ],
      ),
    );
  }
}