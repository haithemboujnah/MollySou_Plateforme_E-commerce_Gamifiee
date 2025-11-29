from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import re
import random
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
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as e:
        print(f"Database connection error: {e}")
        return None


CHATBOT_KNOWLEDGE = {
    'greetings': {
        'patterns': [
            r'bonjour', r'salut', r'hello', r'coucou', r'hey',
            r'bonsoir', r'bonne nuit'
        ],
        'responses': [
            "Bonjour ! Je suis votre assistant MollySou. Comment puis-je vous aider aujourd'hui ?",
            "Salut ! Ravie de vous voir. Que cherchez-vous ?",
            "Hello ! Je suis là pour vous aider à trouver les meilleurs produits."
        ]
    },
    'help': {
        'patterns': [
            r'aide', r'help', r'assistance', r'support',
            r'comment.*utiliser', r'que puis.*faire'
        ],
        'responses': [
            "Je peux vous aider à :\n• Trouver des produits par catégorie\n• Rechercher des articles dans votre budget\n• Vous suggérer des promotions\n• Répondre à vos questions sur MollySou",
            "Voici ce que je peux faire pour vous :\n- Recherche de produits\n- Suggestions personnalisées\n- Informations sur les promotions\n- Aide à la navigation"
        ]
    },
    'products': {
        'patterns': [
            r'produit', r'article', r'item', r'achat', r'acheter',
            r'quel.*produit', r'meilleur.*produit', r'recommand'
        ],
        'responses': [
            "Je peux vous aider à trouver des produits ! Dites-moi ce que vous cherchez ou votre budget.",
            "Parlons produits ! Quelle catégorie vous intéresse ? Vêtements, Électronique, Beauté..."
        ]
    },
    'budget': {
        'patterns': [
            r'budget', r'prix', r'cher', r'pas cher', r'abordable',
            r'moins de (\d+)', r'jusqu.*à (\d+)', r'maximum (\d+)'
        ],
        'responses': [
            "Excellent ! Je peux vous trouver des produits dans votre budget.",
            "Parfait ! Laissez-moi vous suggérer des articles selon votre budget."
        ]
    },
    'categories': {
        'patterns': [
            r'catégorie', r'type', r'sortes', r'variétés',
            r'vêtements', r'électronique', r'beauté', r'restauration',
            r'santé', r'décoration', r'enfants', r'divertissement'
        ],
        'responses': [
            "Nous avons 8 catégories principales : Vêtements, Électronique, Beauté, Restauration, Santé, Décoration, Enfants, Divertissement.",
            "Voici nos catégories : Vêtements 👕, Électronique 📱, Beauté 💄, Restauration 🍽️, Santé 🏥, Décoration 🏠, Enfants 👶, Divertissement 🎮"
        ]
    },
    'promotions': {
        'patterns': [
            r'promotion', r'réduction', r'solde', r'offre', r'rabais',
            r'bon plan', r'prix réduit', r'discount'
        ],
        'responses': [
            "En fonction de votre niveau, vous bénéficiez de réductions exclusives !",
            "Votre rang vous donne droit à des promotions spéciales. Voulez-vous savoir votre réduction actuelle ?"
        ]
    },
    'thanks': {
        'patterns': [
            r'merci', r'thanks', r'gracías', r'apprécie',
            r'super', r'génial', r'parfait'
        ],
        'responses': [
            "Avec plaisir ! N'hésitez pas si vous avez d'autres questions.",
            "Je suis ravi d'avoir pu vous aider ! 😊",
            "Toujours là pour vous aider !"
        ]
    }
}

SUGGESTIONS = [
    "Je cherche des produits pour",
    "Quels sont les meilleurs",
    "Avez-vous des promotions sur",
    "Montrez-moi des",
    "Je veux acheter",
    "Budget maximum",
    "Produits populaires en",
    "Nouveaux articles dans",
    "Cadeaux pour",
    "Articles de luxe"
]

@app.route('/api/chatbot/message', methods=['POST'])
def handle_chat_message():
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
            
        message = data.get('message', '').lower().strip()
        user_id = data.get('user_id')
        
        if not message:
            return jsonify({'error': 'Message vide'}), 400
        
        response_category = None
        for category, info in CHATBOT_KNOWLEDGE.items():
            for pattern in info['patterns']:
                if re.search(pattern, message, re.IGNORECASE):
                    response_category = category
                    break
            if response_category:
                break
        
        if not response_category:
            response = "Je ne suis pas sûr de comprendre. Pouvez-vous reformuler ? Je peux vous aider avec : produits, budget, catégories, promotions..."
        else:
            response = random.choice(CHATBOT_KNOWLEDGE[response_category]['responses'])
        
        budget_match = re.search(r'(\d+)\s*(dt|dinars|euros?|€|\$)?', message, re.IGNORECASE)
        if budget_match:
            budget = int(budget_match.group(1))
            response += f"\n\nAvec un budget de {budget} DT, voici ce que je vous recommande :"
            budget_recommendations = get_budget_recommendations(budget, user_id)
            response += budget_recommendations
        
        category_products = detect_category_products(message)
        if category_products:
            response += f"\n\n{category_products}"
        
        return jsonify({
            'response': response,
            'category': response_category,
            'suggestions': get_suggestions_based_on_message(message)  
        })
        
    except Exception as e:
        print(f"Error in handle_chat_message: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/chatbot/suggestions', methods=['GET'])
def get_chat_suggestions():  
    try:
        query = request.args.get('q', '').lower().strip()
        
        if not query:
            return jsonify({
                'suggestions': SUGGESTIONS,
                'type': 'general'
            })
        
        filtered_suggestions = [
            suggestion for suggestion in SUGGESTIONS 
            if query in suggestion.lower()
        ]
        
        if any(word in query for word in ['produit', 'article', 'acheter']):
            filtered_suggestions.extend([
                "Produits populaires cette semaine",
                "Nouveautés à découvrir",
                "Meilleures ventes du moment"
            ])
        
        if any(word in query for word in ['prix', 'budget', 'cher']):
            filtered_suggestions.extend([
                "Articles moins de 50 DT",
                "Produits premium au-dessus de 200 DT",
                "Meilleurs rapports qualité-prix"
            ])
        
        if any(word in query for word in ['cadeau', 'offrir']):
            filtered_suggestions.extend([
                "Cadeaux pour homme",
                "Cadeaux pour femme",
                "Cadeaux pour enfants",
                "Cadeaux originaux"
            ])
        
        return jsonify({
            'suggestions': filtered_suggestions[:8],  
            'type': 'contextual'
        })
        
    except Exception as e:
        print(f"Error in get_chat_suggestions: {e}")
        return jsonify({'error': str(e)}), 500

def get_suggestions_based_on_message(message):  
    """Retourne des suggestions basées sur le message"""
    message_lower = message.lower()
    
    if any(word in message_lower for word in ['budget', 'prix', 'cher']):
        return [
            "Budget maximum 50 DT",
            "Articles moins de 100 DT", 
            "Produits premium 200+ DT"
        ]
    elif any(word in message_lower for word in ['produit', 'article']):
        return [
            "Produits populaires",
            "Nouveautés",
            "Meilleures ventes"
        ]
    elif any(word in message_lower for word in ['cadeau', 'offrir']):
        return [
            "Cadeaux pour homme",
            "Cadeaux pour femme", 
            "Cadeaux enfants"
        ]
    else:
        return SUGGESTIONS[:5]

def get_budget_recommendations(budget, user_id):
    try:
        conn = get_db_connection()
        if not conn:
            return "\nDésolé, service temporairement indisponible."
            
        cursor = conn.cursor(dictionary=True)
        
        if budget < 50:
            cursor.execute("""
                SELECT p.nom, p.prix, c.nom as category 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE p.prix <= %s AND p.disponible = TRUE 
                ORDER BY p.rating DESC 
                LIMIT 5
            """, (budget,))
        else:
            cursor.execute("""
                SELECT p.nom, p.prix, c.nom as category 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE p.prix BETWEEN %s AND %s AND p.disponible = TRUE 
                ORDER BY p.rating DESC 
                LIMIT 5
            """, (budget * 0.7, budget))
        
        products = cursor.fetchall()
        conn.close()
        
        if not products:
            return "\nAucun produit trouvé dans ce budget. Essayez d'augmenter votre budget ou cherchez dans d'autres catégories."
        
        recommendations = []
        for product in products:
            recommendations.append(f"• {product['nom']} - {product['prix']} DT ({product['category']})")
        
        return "\n" + "\n".join(recommendations) + "\n\nVoulez-vous voir plus de détails sur l'un de ces produits ?"
        
    except Exception as e:
        print(f"Error in get_budget_recommendations: {e}")
        return f"\nDésolé, je ne peux pas accéder aux recommandations pour le moment."

def detect_category_products(message):
    try:
        conn = get_db_connection()
        if not conn:
            return None
            
        cursor = conn.cursor(dictionary=True)
        
        categories_keywords = {
            'Vêtements': ['vêtements', 'vetement', 'habit', 'tshirt', 'robe', 'jean'],
            'Électronique': ['électronique', 'electronique', 'smartphone', 'tablette', 'casque'],
            'Beauté': ['beauté', 'beaute', 'cosmétique', 'maquillage', 'parfum'],
            'Restauration': ['restauration', 'restaurant', 'repas', 'cuisine'],
            'Santé': ['santé', 'sante', 'médecin', 'massage', 'vitamine'],
            'Décoration': ['décoration', 'decoration', 'meuble', 'canapé', 'lampe'],
            'Enfants': ['enfant', 'bébé', 'bebe', 'jouet', 'poussette'],
            'Divertissement': ['divertissement', 'jeu', 'cinéma', 'escape game']
        }
        
        detected_category = None
        for category, keywords in categories_keywords.items():
            if any(keyword in message.lower() for keyword in keywords):
                detected_category = category
                break
        
        if detected_category:
            cursor.execute("""
                SELECT p.nom, p.prix, p.rating 
                FROM products p 
                JOIN categories c ON p.category_id = c.id 
                WHERE c.nom = %s AND p.disponible = TRUE 
                ORDER BY p.rating DESC 
                LIMIT 3
            """, (detected_category,))
            
            products = cursor.fetchall()
            conn.close()
            
            if products:
                product_list = []
                for product in products:
                    product_list.append(f"• {product['nom']} - {product['prix']} DT ⭐{product['rating']}")
                
                return f"Voici les meilleurs produits en {detected_category} :\n" + "\n".join(product_list)
        
        conn.close()
        return None
        
    except Exception as e:
        print(f"Error in detect_category_products: {e}")
        return None

@app.route('/api/chatbot/user/products', methods=['GET'])
def get_user_recommended_products():
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'error': 'User ID required'}), 400
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': 'Database connection failed'}), 500
            
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT genre, niveau FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user_genre = user['genre'].lower() if user['genre'] else 'homme'
        user_level = user['niveau']
        
        if user_genre == 'homme':
            categories = ['Vêtements', 'Électronique', 'Divertissement']
        elif user_genre == 'femme':
            categories = ['Vêtements', 'Beauté', 'Décoration']
        else:
            categories = ['Vêtements', 'Électronique', 'Divertissement']
        
        if user_level >= 100:
            categories.append('Restauration')  
        
        placeholders = ', '.join(['%s'] * len(categories))
        query = f"""
            SELECT p.*, c.nom as category_nom 
            FROM products p 
            JOIN categories c ON p.category_id = c.id 
            WHERE c.nom IN ({placeholders}) AND p.disponible = TRUE 
            ORDER BY p.rating DESC 
            LIMIT 6
        """
        
        cursor.execute(query, categories)
        products = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'products': products,
            'recommendation_reason': f"Basé sur votre profil {user_genre} et niveau {user_level}"
        })
        
    except Exception as e:
        print(f"Error in get_user_recommended_products: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/chatbot/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'OK', 'message': 'Chatbot API is running'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)