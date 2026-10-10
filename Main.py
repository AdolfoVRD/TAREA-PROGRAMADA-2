from curses import window
import pyodbc # La librería pyodbc permite conectarse a bases de datos SQL Server desde Python.
from flask import Flask, jsonify, request
from flask_cors import CORS
import webbrowser
from pyscript import Element, display, when, document


webbrowser.open("index.html")  # Abre el navegador web en la URL especificada
app = Flask(__name__)
CORS(app)

# Conexión a la base de datos local SQL Server utilizando pyodbc
try:
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "Server=localhost;"
        "Database=CuentaAhorro;"
        "Trusted_Connection=yes;"
        "Encrypt=no;"
        "TrustServerCertificate=yes;"
    )
    # Se crea un puntero para ejecutar consultas SQL en la base de datos utilizando la conexión
    cursor = conn.cursor()
except pyodbc.Error:
    print("Error de conexión a la base de datos")


@when("click", "#inicioSesion")
def handleLogin(event):
    # Obtiene los valores de usuario y contraseña desde los elementos HTML
    usuario = document.getElementById("usuario").value
    constraseña = document.getElementById("constraseña").value

    # Consulta SQL para verificar si el usuario y la contraseña existen en la base de datos
    
    cursor.execute("EXEC dbo.SpConsultarUsuarios")
    result = False
    for row in cursor.fetchall():
        if row.User_ == usuario and row.Pass == constraseña:
            document.getElementById("mensaje").innerHTML = "Inicio de sesión exitoso"
            break

    
        # Si no se encuentra un resultado, significa que el inicio de sesión ha fallado
        document.getElementById("mensaje").innerHTML = "Usuario o contraseña incorrectos"

