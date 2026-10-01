import pyodbc # La librería pyodbc permite conectarse a bases de datos SQL Server desde Python.
from flask import Flask, jsonify, request
from flask_cors import CORS
import webbrowser



webbrowser.open("index.html")  # Abre el navegador web en la URL especificada
app = Flask(__name__)
CORS(app)

# Conexión a la base de datos local SQL Server utilizando pyodbc
try:
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "Server=localhost;"
        "Database=master;"
        "Trusted_Connection=yes;"
        "Encrypt=no;"
        "TrustServerCertificate=yes;"
    )
    # Se crea un puntero para ejecutar consultas SQL en la base de datos utilizando la conexión
    cursor = conn.cursor()
except pyodbc.Error:
    print("Error de conexión a la base de datos")

