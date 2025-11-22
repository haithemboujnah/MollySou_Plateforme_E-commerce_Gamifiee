import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onClose;
  final bool isDarkMode;
  final VoidCallback toggleDarkMode;

  const Sidebar({
    Key? key,
    required this.userData,
    required this.onClose,
    required this.isDarkMode,
    required this.toggleDarkMode,
  }) : super(key: key);

  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // Couleurs pour le mode sombre
  Color get _backgroundColor => widget.isDarkMode ? Color(0xFF1A1A2E) : Colors.white;
  Color get _textColor => widget.isDarkMode ? Colors.white : Color(0xFF2D3748);
  Color get _secondaryTextColor => widget.isDarkMode ? Colors.white70 : Colors.grey[600]!;
  Color get _cardColor => widget.isDarkMode ? Color(0xFF16213E) : Color(0xFFF8FAFC);
  Color get _accentColor => Color(0xFF6A11CB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(-2, 0),
          ),
        ],
      ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildUserProfile(),
                _buildStatsSection(),
                _buildMenuItems(),
                _buildSettingsSection(),
                SizedBox(height: 20),
                _buildFooter(),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menu',
            style: GoogleFonts.aBeeZee(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: _textColor, size: 28),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 2),
              image: DecorationImage(
                image: NetworkImage(widget.userData["photoProfil"]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData["nomComplet"],
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Niveau ${widget.userData["level"]}',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                // Progress Bar
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width * 0.85 - 120) *
                            (widget.userData["xpActuel"] / widget.userData["xpProchainNiveau"]),
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${widget.userData["xpActuel"]}/${widget.userData["xpProchainNiveau"]} XP',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Points
          _buildStatItem(
            icon: Icons.emoji_events,
            title: 'Points',
            value: '${widget.userData["points"]}',
            color: Colors.amber,
          ),

          // Rank
          _buildStatItem(
            icon: Icons.star,
            title: 'Rank',
            value: widget.userData["rank"],
            color: _getRankColor(widget.userData["rank"]),
          ),

          // Discount
          _buildStatItem(
            icon: Icons.local_offer,
            title: 'Réduction',
            value: _getDiscountForRank(widget.userData["rank"]),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navigation',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          _buildMenuItem(
            icon: Icons.shopping_bag,
            title: 'Boutique',
            onTap: () {
              // Navigate to shop
              widget.onClose();
            },
          ),

          _buildMenuItem(
            icon: Icons.history,
            title: 'Historique',
            onTap: () {
              // Navigate to history
              widget.onClose();
            },
          ),

          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Favoris',
            onTap: () {
              // Navigate to favorites
              widget.onClose();
            },
          ),

          _buildMenuItem(
            icon: Icons.card_giftcard,
            title: 'Récompenses',
            onTap: () {
              // Navigate to rewards
              widget.onClose();
            },
          ),

          _buildMenuItem(
            icon: Icons.help,
            title: 'Aide & Support',
            onTap: () {
              // Navigate to help
              widget.onClose();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _accentColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: _secondaryTextColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          // Dark Mode Toggle
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.orange,
                size: 20,
              ),
            ),
            title: Text(
              'Mode Sombre',
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (value) {
                widget.toggleDarkMode();
              },
              activeColor: _accentColor,
            ),
            onTap: widget.toggleDarkMode,
            contentPadding: EdgeInsets.zero,
          ),

          // Notifications
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              // Navigate to notifications
              widget.onClose();
            },
          ),

          // Privacy
          _buildMenuItem(
            icon: Icons.security,
            title: 'Confidentialité',
            onTap: () {
              // Navigate to privacy
              widget.onClose();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode ? Color(0xFF0F3460) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            'MollySou',
            style: GoogleFonts.aBeeZee(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Votre centre commercial gamifié',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank.toUpperCase()) {
      case 'DIAMOND':
        return Color(0xFF1E3A8A);
      case 'PLATINUM':
        return Color(0xFF0BC5EA);
      case 'GOLD':
        return Color(0xFFFFD700);
      case 'SILVER':
        return Color(0xFFC0C0C0);
      case 'BRONZE':
        return Color(0xFFCD7F32);
      default:
        return _accentColor;
    }
  }

  String _getDiscountForRank(String rank) {
    switch (rank.toUpperCase()) {
      case 'DIAMOND':
        return '50%';
      case 'PLATINUM':
        return '20%';
      case 'GOLD':
        return '15%';
      case 'SILVER':
        return '10%';
      case 'BRONZE':
        return '5%';
      default:
        return '0%';
    }
  }
}