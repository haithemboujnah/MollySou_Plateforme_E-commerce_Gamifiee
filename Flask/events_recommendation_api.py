from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime
import random

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

EVENT_RECOMMENDATIONS = {
    'homme': {
        'preferences': ['SPORT', 'CONCERT', 'ESPORT', 'AUTO', 'JEUX'],
        'budget_range': (20, 100),
        'keywords': ['sport', 'football', 'concert', 'rock', 'gaming', 'voiture']
    },
    'femme': {
        'preferences': ['THEATRE', 'CONCERT', 'DANSE', 'CULTURE', 'HUMOUR'],
        'budget_range': (25, 80),
        'keywords': ['théâtre', 'musical', 'danse', 'art', 'comédie', 'culture']
    },
    'jeune': {
        'preferences': ['CONCERT', 'ESPORT', 'SPORT', 'HUMOUR', 'SPECTACLE'],
        'budget_range': (15, 50),
        'keywords': ['concert', 'gaming', 'sport', 'humour', 'festival']
    },
    'famille': {
        'preferences': ['CULTURE', 'SPECTACLE', 'THEATRE', 'GASTRONOMIE', 'DANSE'],
        'budget_range': (15, 60),
        'keywords': ['famille', 'culture', 'spectacle', 'gastronomie', 'danse']
    },
    'visiteur': {
        'preferences': ['CULTURE', 'SPECTACLE', 'CONCERT', 'THEATRE', 'GASTRONOMIE'],
        'budget_range': (20, 70),
        'keywords': ['culture', 'spectacle', 'concert', 'théâtre', 'gastronomie']
    }
}

@app.route('/api/events/recommendations', methods=['GET'])
def get_event_recommendations():
    try:
        user_id = request.args.get('user_id', type=int)
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        user_profile = None
        if user_id:
            cursor.execute("SELECT genre, niveau, points FROM users WHERE id = %s", (user_id,))
            user = cursor.fetchone()
            
            if user:
                user_genre = user['genre'].lower() if user['genre'] else 'visiteur'
                user_level = user['niveau']
                user_points = user['points']
                
                if user_genre in ['homme', 'femme']:
                    user_profile = user_genre
                elif user_level < 30:
                    user_profile = 'jeune'
                elif user_level >= 100 and user_points > 1000:
                    user_profile = 'famille'
                else:
                    user_profile = 'visiteur'
        
        if not user_profile:
            user_profile = 'visiteur'
        
        current_date = datetime.now().strftime('%Y-%m-%d')
        cursor.execute("""
            SELECT * FROM events 
            WHERE date >= %s 
            ORDER BY rating DESC, date ASC
        """, (current_date,))
        
        all_events = cursor.fetchall()
        
        profile_prefs = EVENT_RECOMMENDATIONS.get(user_profile, EVENT_RECOMMENDATIONS['visiteur'])
        recommended_events = []
        
        for event in all_events:
            score = 0
            
            if event['type'] in profile_prefs['preferences']:
                score += 3
            
            min_budget, max_budget = profile_prefs['budget_range']
            if min_budget <= event['prix'] <= max_budget:
                score += 2
            elif event['prix'] < min_budget:
                score += 1
            
            score += event['rating'] - 4.0  
            
            event_date = event['date']
            days_until_event = (event_date - datetime.now().date()).days
            if days_until_event <= 7:
                score += 2
            elif days_until_event <= 14:
                score += 1
            
            recommended_events.append({
                **event,
                'recommendation_score': score,
                'recommendation_reason': get_recommendation_reason(event, user_profile, score)
            })
        
        recommended_events.sort(key=lambda x: x['recommendation_score'], reverse=True)
        
        top_events = recommended_events[:4]
        
        conn.close()
        
        return jsonify({
            'events': top_events,
            'user_profile': user_profile,
            'recommendation_based': True,
            'total_events': len(all_events)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/popular', methods=['GET'])
def get_popular_events():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        current_date = datetime.now().strftime('%Y-%m-%d')
        cursor.execute("""
            SELECT * FROM events 
            WHERE date >= %s 
            ORDER BY rating DESC, places_disponibles DESC 
            LIMIT 6
        """, (current_date,))
        
        events = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'events': events,
            'recommendation_based': False
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/search', methods=['GET'])
def search_events():
    try:
        query = request.args.get('q', '').lower().strip()
        event_type = request.args.get('type', '')
        max_price = request.args.get('max_price', type=float)
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        current_date = datetime.now().strftime('%Y-%m-%d')
        sql = "SELECT * FROM events WHERE date >= %s"
        params = [current_date]
        
        if query:
            sql += " AND (LOWER(titre) LIKE %s OR LOWER(description) LIKE %s OR LOWER(lieu) LIKE %s)"
            params.extend([f'%{query}%', f'%{query}%', f'%{query}%'])
        
        if event_type:
            sql += " AND type = %s"
            params.append(event_type)
        
        if max_price:
            sql += " AND prix <= %s"
            params.append(max_price)
        
        sql += " ORDER BY rating DESC, date ASC"
        
        cursor.execute(sql, params)
        events = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'events': events,
            'search_query': query,
            'total_results': len(events)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/types', methods=['GET'])
def get_event_types():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT DISTINCT type FROM events ORDER BY type")
        types = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'types': [t['type'] for t in types]
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def get_recommendation_reason(event, user_profile, score):
    reasons = []
    
    if event['type'] in EVENT_RECOMMENDATIONS[user_profile]['preferences'][:2]:
        reasons.append("Correspond à vos préférences")
    
    if event['rating'] >= 4.7:
        reasons.append("Très bien noté")
    elif event['rating'] >= 4.5:
        reasons.append("Bien noté")
    
    event_date = event['date']
    days_until = (event_date - datetime.now().date()).days
    if days_until <= 3:
        reasons.append("Prochainement")
    elif days_until <= 7:
        reasons.append("Cette semaine")
    
    if event['prix'] <= 30:
        reasons.append("Bon prix")
    
    if len(reasons) > 0:
        return " • ".join(reasons[:2])
    else:
        return "Événement populaire"

@app.route('/api/events/<int:event_id>', methods=['GET'])
def get_event_details(event_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT * FROM events WHERE id = %s", (event_id,))
        event = cursor.fetchone()
        
        if not event:
            conn.close()
            return jsonify({'error': 'Événement non trouvé'}), 404
        
        cursor.execute("""
            SELECT * FROM events 
            WHERE type = %s AND id != %s AND date >= %s 
            ORDER BY rating DESC 
            LIMIT 3
        """, (event['type'], event_id, datetime.now().strftime('%Y-%m-%d')))
        
        similar_events = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'event': event,
            'similar_events': similar_events
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5002, host='0.0.0.0')