import mysql.connector

def get_db_connection():
    connection = mysql.connector.connect(
        host='localhost',
        user='root',
        password='1234',
        database='animalia',
        connection_timeout=30 
    )
    return connection
