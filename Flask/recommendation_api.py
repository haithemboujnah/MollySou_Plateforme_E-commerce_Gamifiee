from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime

app = Flask(__name__)
CORS(app)

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'mollysou_db'
}

def get_db_connection():
    return mysql.connector.connect(**db_config)

RECOMMENDATION_PROFILES = {
    'homme': ['Vêtements', 'Électronique', 'Divertissement', 'Restauration'],
    'femme': ['Vêtements', 'Beauté', 'Décoration', 'Restauration', 'Santé'],
    'jeune': ['Électronique', 'Divertissement', 'Vêtements', 'Restauration'],
    'bebe': ['Enfants', 'Santé'],
    'visiteur': ['Vêtements', 'Électronique', 'Restauration', 'Divertissement', 'Beauté'],
    'famille': ['Enfants', 'Décoration', 'Restauration', 'Divertissement', 'Santé']
}

SEARCH_KEYWORDS = {
    'homme': ['homme', 'masculin', 'mâle', 'male', 'men', 'man', 'garçon', 'gars'],
    'femme': ['femme', 'féminin', 'féminine', 'feminin', 'feminine', 'women', 'woman', 'fille', 'dame'],
    'jeune': ['jeune', 'jeunes', 'youth', 'teen', 'adolescent', 'ado', 'student', 'étudiant'],
    'bebe': ['bébé', 'bebe', 'baby', 'bébés', 'bebes', 'babies', 'nourrisson', 'enfant'],
    'visiteur': ['visiteur', 'visiteurs', 'visitor', 'touriste', 'tourist', 'nouveau', 'new'],
    'famille': ['famille', 'family', 'parent', 'parents', 'maman', 'papa', 'mother', 'father']
}

@app.route('/api/search/categories', methods=['GET'])
def search_categories():
    try:
        search_term = request.args.get('q', '').lower().strip()
        user_id = request.args.get('user_id', type=int)
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        user_genre = None
        if user_id:
            cursor.execute("SELECT genre FROM users WHERE id = %s", (user_id,))
            user_result = cursor.fetchone()
            if user_result:
                user_genre = user_result['genre'].lower() if user_result['genre'] else None
        
        if not search_term:
            cursor.execute("SELECT * FROM categories ORDER BY nom")
            categories = cursor.fetchall()
            conn.close()
            return jsonify({
                'categories': categories,
                'search_type': 'all',
                'recommendation_based': False
            })
        
        if len(search_term) < 2:
            detected_profile = None
            print("Searching for profile based on user genre:", user_genre)
        else:
            detected_profile = None
            for profile, keywords in SEARCH_KEYWORDS.items():
                if any(keyword in search_term for keyword in keywords):
                    detected_profile = profile
                    break
        
        if detected_profile:
            recommended_categories = RECOMMENDATION_PROFILES.get(detected_profile, [])
            placeholders = ', '.join(['%s'] * len(recommended_categories))
            query = f"SELECT * FROM categories WHERE nom IN ({placeholders}) ORDER BY nom"
            cursor.execute(query, recommended_categories)
            categories = cursor.fetchall()
            
            conn.close()
            return jsonify({
                'categories': categories,
                'search_type': 'recommendation',
                'profile': detected_profile,
                'recommendation_based': True
            })
        
        cursor.execute("""
            SELECT * FROM categories 
            WHERE LOWER(nom) LIKE %s OR LOWER(description) LIKE %s 
            ORDER BY nom
        """, (f'%{search_term}%', f'%{search_term}%'))
        
        categories = cursor.fetchall()
        
        if not categories:
            cursor.execute("""
                SELECT c.* FROM categories c
                LEFT JOIN products p ON c.id = p.category_id
                WHERE LOWER(p.nom) LIKE %s OR LOWER(p.description) LIKE %s
                GROUP BY c.id
                ORDER BY c.nom
            """, (f'%{search_term}%', f'%{search_term}%'))
            categories = cursor.fetchall()
        
        conn.close()
        
        return jsonify({
            'categories': categories,
            'search_type': 'normal',
            'recommendation_based': False
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/search/products', methods=['GET'])
def search_products():
    try:
        search_term = request.args.get('q', '').lower().strip()
        category_id = request.args.get('category_id', type=int)
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        if category_id:
            cursor.execute("""
                SELECT p.*, c.nom as category_nom 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE p.category_id = %s AND p.disponible = TRUE
                ORDER BY p.rating DESC
            """, (category_id,))
        elif search_term:
            cursor.execute("""
                SELECT p.*, c.nom as category_nom 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE (LOWER(p.nom) LIKE %s OR LOWER(p.description) LIKE %s) 
                AND p.disponible = TRUE
                ORDER BY p.rating DESC
            """, (f'%{search_term}%', f'%{search_term}%'))
        else:
            cursor.execute("""
                SELECT p.*, c.nom as category_nom 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE p.disponible = TRUE 
                ORDER BY p.rating DESC 
                LIMIT 20
            """)
        
        products = cursor.fetchall()
        conn.close()
        
        return jsonify({'products': products})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/user/recommendations', methods=['GET'])
def get_user_recommendations():
    try:
        user_id = request.args.get('user_id', type=int)
        
        if not user_id:
            return jsonify({'error': 'User ID required'}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT genre, niveau FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user_genre = user['genre'].lower() if user['genre'] else 'visiteur'
        user_level = user['niveau']
        
        profile = user_genre
        if user_level < 30:
            profile = 'jeune'
        elif user_genre in ['homme', 'femme'] and user_level >= 100:
            profile = 'famille'
        
        recommended_categories = RECOMMENDATION_PROFILES.get(profile, [])
        placeholders = ', '.join(['%s'] * len(recommended_categories))
        
        if recommended_categories:
            query = f"SELECT * FROM categories WHERE nom IN ({placeholders}) ORDER BY nom"
            cursor.execute(query, recommended_categories)
            categories = cursor.fetchall()
        else:
            cursor.execute("SELECT * FROM categories ORDER BY nom LIMIT 6")
            categories = cursor.fetchall()
        
        conn.close()
        
        return jsonify({
            'categories': categories,
            'profile': profile,
            'user_genre': user_genre,
            'user_level': user_level
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000, host='0.0.0.0')