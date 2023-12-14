from aifc import Error
import base64
from flask import Flask, request, jsonify
from db import get_db_connection
from werkzeug.security import generate_password_hash
import mysql.connector

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Teste'

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()  

    if not data:
        return jsonify({'error': 'O corpo da solicitação não está no formato JSON esperado'}), 400

    petname = data.get('petname')
    petpicture_base64 = data.get('petpicture')
    print(type(petpicture_base64))
    petpicture = base64.b64decode(petpicture_base64) if petpicture_base64 else None
    description = data.get('description')
    date_of_birth = data.get('date_of_birth')
    email = data.get('email')
    password = data.get('password')  

    
    db = get_db_connection()
    cursor = db.cursor(buffered=True)
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    existing_user = cursor.fetchone()
    
    if existing_user:
        cursor.close()
        db.close()
        return jsonify({'error': 'Email already exists'}), 409  

    try:
        
        cursor.execute(
            """
            INSERT INTO users (petname, petpicture, description, date_of_birth, email, password)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (petname, petpicture, description, date_of_birth, email, password)
        )
        db.commit()
        user_id = cursor.lastrowid
        return jsonify({'message': 'User registered successfully', 'user_id': user_id}), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    

    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data['email']
    password = data['password']

    
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
    user = cursor.fetchone()
    cursor.close()
    db.close()

    if user and user['password'] == password:
        
        user.pop('password', None)
        user['petpicture'] = base64.b64encode(user['petpicture']).decode('utf-8')
        return jsonify({'message': 'Login successful', 'user': user}), 200
    else:
        return jsonify({'message': 'Invalid email or password'}), 401
    
    

    
@app.route('/search', methods=['GET'])
def search_users():
    petname_search = request.args.get('petname', default='', type=str)
    user_searching_id = request.args.get('user_id', type=int)

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    query = """
        SELECT 
            users.*, 
            EXISTS (
                SELECT 1 
                FROM friends 
                WHERE (friends.user_id = users.user_id AND friends.friend_id = %s) 
                    OR (friends.friend_id = users.user_id AND friends.user_id = %s)
            ) as isFriend 
        FROM users 
        WHERE users.petname LIKE %s;
    """
    try:
        cursor.execute(query, (user_searching_id, user_searching_id, f"%{petname_search}%"))
        users = cursor.fetchall()
        
        
        for user in users:
            if isinstance(user['petpicture'], bytes):
                user['petpicture'] = base64.b64encode(user['petpicture']).decode('utf-8')
        
        return jsonify(users), 200
    except mysql.connector.Error as err:
        print("Erro ao executar a consulta:", err)
        return jsonify({'error': str(err)}), 500
    finally:
        cursor.close()
        db.close()
    
@app.route('/post', methods=['POST'])
def create_post():
    
    data = request.get_json()
    user_id = data.get('user_id')
    description = data.get('description')
    image_data = data.get('image_data')  

    
    db = get_db_connection()
    cursor = db.cursor()

    
    image_data_binary = base64.b64decode(image_data)

    try:
        
        sql = """
            INSERT INTO posts (user_id, description, image_data) 
            VALUES (%s, %s, %s)
        """
        cursor.execute(sql, (user_id, description, image_data_binary))
        db.commit()
        
        return jsonify({'message': 'Post created successfully', 'post_id': cursor.lastrowid}), 201
    except Exception as e:
        print(e)
        
        return jsonify({'message': 'Failed to create post'}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/user_posts/<int:user_id>', methods=['GET'])
def get_user_posts(user_id):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    
    try:
        query = """
        SELECT p.*, u.petname as userName, u.petpicture as userImage
        FROM posts p
        INNER JOIN friends f ON (f.friend_id = p.user_id OR f.user_id = p.user_id)
        INNER JOIN users u ON u.user_id = p.user_id
        WHERE f.user_id = %s OR f.friend_id = %s
        GROUP BY p.post_id
        """
        cursor.execute(query, (user_id, user_id))
        posts = cursor.fetchall()

        for post in posts:
            cursor.execute("SELECT * FROM comments WHERE post_id = %s", (post['post_id'],))
            comments = cursor.fetchall()
            post['comments'] = comments

            if isinstance(post['userImage'], bytes):
                post['userImage'] = base64.b64encode(post['userImage']).decode('utf-8')
            if isinstance(post['image_data'], bytes):
                post['image_data'] = base64.b64encode(post['image_data']).decode('utf-8')

        return jsonify(posts), 200
    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return jsonify({'error': f'Database error: {str(err)}'}), 500
    except Exception as e:
        print(f"Server error: {e}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()


@app.route('/user_posts_count/<int:user_id>', methods=['GET'])
def get_user_posts_count(user_id):
    db = get_db_connection()
    cursor = db.cursor()
    
    try:
        cursor.execute("SELECT COUNT(*) FROM posts WHERE user_id = %s", (user_id,))
        count = cursor.fetchone()[0]
        return jsonify(count), 200
    except Exception as e:
        print(e)
        return jsonify({'error': 'Failed to fetch posts count'}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/add_friend', methods=['POST'])
def add_friend():
    data = request.get_json()
    user_id = data['user_id']
    friend_id = data['friend_id']

    db = get_db_connection()
    cursor = db.cursor()

    try:
        
        cursor.execute("INSERT INTO friends (user_id, friend_id) VALUES (%s, %s)", (user_id, friend_id))
        db.commit()
        return jsonify({'message': 'Friend added successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/friends_count/<int:user_id>', methods=['GET'])
def get_friends_count(user_id):
    db = get_db_connection()
    cursor = db.cursor()

    try:
        cursor.execute("SELECT COUNT(*) FROM friends WHERE user_id = %s OR friend_id = %s", (user_id, user_id))
        count = cursor.fetchone()[0]
        return jsonify({'count': count}), 200
    except Exception as e:
        print(e)
        return jsonify({'error': 'Failed to fetch friends count'}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/remove_friend/<int:user_id>/<int:friend_id>', methods=['DELETE'])
def remove_friend(user_id, friend_id):
    db = get_db_connection()
    cursor = db.cursor()

    try:
        
        delete_query = """
        DELETE FROM friends
        WHERE (user_id = %s AND friend_id = %s) OR (user_id = %s AND friend_id = %s)
        """
        cursor.execute(delete_query, (user_id, friend_id, friend_id, user_id))
        db.commit()

        if cursor.rowcount == 0:
            
            return jsonify({'message': 'No friendship found'}), 404

        return jsonify({'message': 'Friendship removed successfully'}), 200

    except mysql.connector.Error as err:
        print("Erro ao executar a consulta:", err)
        return jsonify({'error': 'Database error'}), 500

    finally:
        cursor.close()
        db.close()

@app.route('/check_friendship', methods=['GET'])
def check_friendship():
    current_user_id = request.args.get('currentUserId', type=int)
    friend_id = request.args.get('friendId', type=int)

    db = get_db_connection()
    cursor = db.cursor()

    try:
        cursor.execute("""
            SELECT EXISTS(
                SELECT 1 FROM friends 
                WHERE (user_id = %s AND friend_id = %s) 
                OR (user_id = %s AND friend_id = %s)
            )
        """, (current_user_id, friend_id, friend_id, current_user_id))
        is_friend = cursor.fetchone()[0]
        return jsonify({'isFriend': is_friend}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/friend_posts/<int:user_id>', methods=['GET'])
def get_friend_posts(user_id):
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    
    try:
        query = """
        SELECT p.*, u.petname as userName, u.petpicture as userImage
        FROM posts p
        INNER JOIN friends f ON (f.friend_id = p.user_id OR f.user_id = p.user_id)
        INNER JOIN users u ON u.user_id = p.user_id
        WHERE (f.user_id = %s OR f.friend_id = %s) AND p.user_id != %s
        GROUP BY p.post_id
        """
        cursor.execute(query, (user_id, user_id, user_id))
        posts = cursor.fetchall()

        for post in posts:
            if isinstance(post['userImage'], bytes):
                post['userImage'] = base64.b64encode(post['userImage']).decode('utf-8')
            if isinstance(post['image_data'], bytes):
                post['image_data'] = base64.b64encode(post['image_data']).decode('utf-8')

        return jsonify(posts), 200
    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return jsonify({'error': f'Database error: {str(err)}'}), 500
    except Exception as e:
        print(f"Server error: {e}")
        return jsonify({'error': f'Server error: {str(e)}'}), 500
    finally:
        cursor.close()
        db.close()





@app.route('/like_post/<int:post_id>', methods=['POST'])
def like_post(post_id):
    db = get_db_connection()
    cursor = db.cursor()

    try:
        
        cursor.execute("UPDATE posts SET likes = likes + 1 WHERE post_id = %s", (post_id,))
        db.commit()

        return jsonify({'message': 'Like added successfully'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()

@app.route('/add_comment', methods=['POST'])
def add_comment():
    data = request.get_json()
    post_id = data['post_id']
    user_id = data['user_id']
    comment_text = data['comment_text']

    db = get_db_connection()
    cursor = db.cursor()

    try:
        cursor.execute("""
            INSERT INTO comments (post_id, user_id, comment_text)
            VALUES (%s, %s, %s)
        """, (post_id, user_id, comment_text))
        db.commit()

        return jsonify({'message': 'Comment added successfully'}), 200
    except Exception as e:
        db.rollback()
        print(e)
        return jsonify({'error': 'Failed to add comment'}), 500
    finally:
        cursor.close()
        db.close()



if __name__ == '__main__':
    app.run(debug=True)