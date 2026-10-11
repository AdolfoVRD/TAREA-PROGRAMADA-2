import pyodbc # La librería pyodbc permite conectarse a bases de datos SQL Server desde Python.
from contextlib import closing
from flask import Flask, jsonify, request, render_template
from flask_cors import CORS
import webbrowser

app = Flask(__name__, template_folder="front", static_folder="front", static_url_path="")
CORS(app)

DATABASE_CONNECTION_STRING = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "Server=localhost;"
    "Database=CuentaAhorro;"
    "Trusted_Connection=yes;"
    "Encrypt=no;"
    "TrustServerCertificate=yes;"
)

usuario_actual = None

def obtener_conexion():
    return pyodbc.connect(DATABASE_CONNECTION_STRING)

def ejecutarSp(nombre, *parametros):
    marcadores = ", ".join("?" for _ in parametros)
    with closing(obtener_conexion()) as conn:
        cursor = conn.cursor()
        cursor.execute(f"EXEC {nombre} {marcadores}", *parametros)
        return cursor.fetchall()

def consultarEstados(usuario):
    filas = ejecutarSp("dbo.SpConsultarEstadosCuenta", usuario)
    return [
        {
            "cuenta": fila.NumeroCuenta,
            "fechaInicio": str(fila.fechaInicio),
            "fechaFin": str(fila.fechafin),
            "saldoInicial": float(fila.saldoinicial),
            "saldoMinimo": float(fila.saldoMinimo),
            "saldoFinal": float(fila.saldo_final),
            "intereses": float(fila.interesesAcumulados),
            "retiros": fila.cantRetiros,
            "depositos": fila.cantDepositos,
            "sinpeEntrantes": fila.cantSinpeEntrantes,
            "sinpeSalientes": fila.cantSinpeSalientes,
        }
        for fila in filas
    ]

@app.route("/")
def index():
    return render_template("index.html")


def convertirArray(Array):
    # Esta funcion convierte el array resultante de la consulta 
    # A Formato json para poder ser enviado al front end
    Lista = []
    Dic = {}
    for fila in Array:
       Dic = {
           "id": fila[0],
           "Nombre": fila[1],
           "Salario": float(fila[2])
       }
       Lista.append(Dic)
       
    return Lista        
       



@app.route("/login", methods=['GET', 'POST'])
def login():
    global usuario_actual
    datos = request.get_json(silent=True)
    if not isinstance(datos, dict):
        return jsonify({"mensaje": "Los datos enviados no son válidos"}), 400

    usuario = datos.get("nombre")
    contraseña = datos.get("contraseña")

    if not isinstance(usuario, str) or not usuario.strip() or not isinstance(contraseña, str) or not contraseña:
        return jsonify({"mensaje": "Faltan datos"}), 400

    try:
        with closing(obtener_conexion()) as conn:
            cursor = conn.cursor()
            cursor.execute("EXEC dbo.SpConsultarUsuarios")
            for row in cursor.fetchall():
                if row.User_ == usuario.strip() and row.Pass == contraseña:
                    usuario_actual = row.User_
                    return jsonify({"mensaje": "Se ha iniciado sesión correctamente", "usuario": row.User_, "id": row.IdUsuario, "esAdministrador": row.EsAdministrador}), 200

        return jsonify({"mensaje": "Usuario o contraseña incorrectos"}), 401
    except pyodbc.Error:
        app.logger.exception("Error al consultar la base de datos durante el inicio de sesión")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

@app.route("/estados")
def estados():
    if usuario_actual is None:
        return jsonify({"mensaje": "Debe iniciar sesión"}), 401
    try:
        return jsonify(consultarEstados(usuario_actual))
    except pyodbc.Error:
        app.logger.exception("Error al consultar los estados de cuenta")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

if __name__ == "__main__":
    webbrowser.open("http://localhost:5000")
    app.run(port=5000)
