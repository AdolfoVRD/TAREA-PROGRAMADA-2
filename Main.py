import pyodbc  # Permite conectarse a SQL Server desde Python
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

# Guarda el usuario que inicio sesion. Como solo una persona usa el sitio
# en localhost, una variable global es suficiente.
usuario_actual = None

# Conexion y ejecucion de procedimientos almacenados

def obtener_conexion():
    # Abre una conexion nueva a la base CuentaAhorro
    return pyodbc.connect(DATABASE_CONNECTION_STRING)


def ejecutarSp(nombre, *parametros):
    # Para consultas. Ejecuta el procedimiento y devuelve las filas.
    # No hace commit porque solo lee datos.
    marcadores = ", ".join("?" for _ in parametros)
    with closing(obtener_conexion()) as conn:
        cursor = conn.cursor()
        cursor.execute(f"EXEC {nombre} {marcadores}", *parametros)
        return cursor.fetchall()


def ejecutarSpEscritura(nombre, *parametros):
    # Para agregar, editar y eliminar. Ejecuta el procedimiento y hace commit
    # para que el cambio quede guardado. No devuelve filas.
    marcadores = ", ".join("?" for _ in parametros)
    with closing(obtener_conexion()) as conn:
        cursor = conn.cursor()
        cursor.execute(f"EXEC {nombre} {marcadores}", *parametros)
        conn.commit()

# Funciones que llaman a cada procedimiento

def validarLogin(usuario, contraseña):
    # Devuelve la fila del usuario si las credenciales son correctas, o None si no
    filas = ejecutarSp("dbo.SpLogin", usuario, contraseña)
    return filas[0] if filas else None

def consultarCuentas(usuario):
    # Devuelve los numeros de cuenta que el usuario puede ver.
    # Si es administrador devuelve todas.
    filas = ejecutarSp("dbo.SpConsultarCuentasUsuario", usuario)
    return [fila.NumeroCuenta for fila in filas]

def consultarEstados(usuario, numeroCuenta):
    # Devuelve los ultimos 8 estados de cuenta, del mas reciente al mas viejo
    filas = ejecutarSp("dbo.SpConsultarEstadosCuenta", usuario, numeroCuenta)
    return [
        {
            "cuenta": fila.NumeroCuenta,
            "fechaInicio": str(fila.fechaInicio),
            "fechaEstado": str(fila.fechafin),
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

def consultarBeneficiarios(numeroCuenta):
    # Devuelve los beneficiarios activos de una cuenta, con su nombre
    filas = ejecutarSp("dbo.SpConsultarBeneficiarios", numeroCuenta)
    return [
        {
            "idBeneficiario": fila.IdBeneficiario,
            "valorDocumento": fila.ValorDocumentoIdentidadBeneficiario,
            "nombre": fila.Nombre,
            "idParentezco": fila.IdParentezco,
            "porcentaje": float(fila.Porcentaje),
        }
        for fila in filas
    ]


def validarAcceso(numeroCuenta):
    # Revisa que haya sesion y que la cuenta pertenezca al usuario.
    # Devuelve una respuesta de error si algo falla, o None si todo esta bien.
    if usuario_actual is None:
        return jsonify({"mensaje": "Debe iniciar sesión"}), 401
    if numeroCuenta not in consultarCuentas(usuario_actual):
        return jsonify({"mensaje": "No tiene permiso sobre esta cuenta"}), 403
    return None

# Rutas de la pagina

@app.route("/")
def index():
    # Pagina de inicio de sesion
    return render_template("index.html")

@app.route("/login", methods=["POST"])
def login():
    # Valida usuario y contraseña, y guarda el usuario que entro
    global usuario_actual
    datos = request.get_json(silent=True)
    if not isinstance(datos, dict):
        return jsonify({"mensaje": "Los datos enviados no son válidos"}), 400

    usuario = datos.get("nombre")
    contraseña = datos.get("contraseña")

    if not isinstance(usuario, str) or not usuario.strip() or not isinstance(contraseña, str) or not contraseña:
        return jsonify({"mensaje": "Faltan datos"}), 400

    try:
        fila = validarLogin(usuario.strip(), contraseña)
        if fila is None:
            return jsonify({"mensaje": "Usuario o contraseña incorrectos"}), 401
        usuario_actual = fila.User_
        return jsonify({
            "mensaje": "Se ha iniciado sesión correctamente",
            "usuario": fila.User_,
            "id": fila.IdUsuario,
            "esAdministrador": bool(fila.EsAdministrador),
            "valorDocId": fila.ValorDocId
        }), 200
    except pyodbc.Error:
        app.logger.exception("Error al consultar la base de datos durante el inicio de sesión")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

@app.route("/cuentas")
def cuentas():
    # Lista de cuentas que el usuario puede ver, para llenar el selector
    if usuario_actual is None:
        return jsonify({"mensaje": "Debe iniciar sesión"}), 401
    try:
        return jsonify(consultarCuentas(usuario_actual))
    except pyodbc.Error:
        app.logger.exception("Error al consultar las cuentas")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

@app.route("/estados/<numero_cuenta>")
def estados(numero_cuenta):
    # Ultimos 8 estados de cuenta de la cuenta escogida
    error = validarAcceso(numero_cuenta)
    if error:
        return error
    try:
        return jsonify(consultarEstados(usuario_actual, numero_cuenta))
    except pyodbc.Error:
        app.logger.exception("Error al consultar los estados de cuenta")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

# Rutas de beneficiarios

@app.route("/beneficiarios/<numero_cuenta>", methods=["GET"])
def listarBeneficiarios(numero_cuenta):
    # Beneficiarios activos de la cuenta
    error = validarAcceso(numero_cuenta)
    if error:
        return error
    try:
        return jsonify(consultarBeneficiarios(numero_cuenta))
    except pyodbc.Error:
        app.logger.exception("Error al consultar los beneficiarios")
        return jsonify({"mensaje": "Error al consultar la base de datos"}), 500

@app.route("/beneficiarios/<numero_cuenta>", methods=["POST"])
def agregarBeneficiario(numero_cuenta):
    # Agrega un beneficiario. El procedimiento valida el maximo de 3 activos
    # y los demas campos, y no hace nada si algo no cumple.
    error = validarAcceso(numero_cuenta)
    if error:
        return error
    datos = request.get_json(silent=True) or {}
    try:
        ejecutarSpEscritura(
            "dbo.SpInsertarBeneficiario", numero_cuenta,
            str(datos.get("valorDocumento", "")).strip(),
            int(datos.get("idParentezco", 0)),
            float(datos.get("porcentaje", 0)))
        return jsonify({"ok": True})
    except (ValueError, TypeError):
        return jsonify({"ok": False}), 400
    except pyodbc.Error:
        app.logger.exception("Error al agregar beneficiario")
        return jsonify({"ok": False}), 500


@app.route("/beneficiarios/<numero_cuenta>/<int:id_beneficiario>", methods=["PUT"])
def editarBeneficiario(numero_cuenta, id_beneficiario):
    # Actualiza nombre, parentesco y porcentaje de un beneficiario
    error = validarAcceso(numero_cuenta)
    if error:
        return error
    datos = request.get_json(silent=True) or {}
    try:
        ejecutarSpEscritura(
            "dbo.SpActualizarBeneficiario", numero_cuenta, id_beneficiario,
            str(datos.get("nombre", "")).strip(),
            int(datos.get("idParentezco", 0)),
            float(datos.get("porcentaje", 0)))
        return jsonify({"ok": True})
    except (ValueError, TypeError):
        return jsonify({"ok": False}), 400
    except pyodbc.Error:
        app.logger.exception("Error al editar beneficiario")
        return jsonify({"ok": False}), 500


@app.route("/beneficiarios/<numero_cuenta>/<int:id_beneficiario>", methods=["DELETE"])
def eliminarBeneficiario(numero_cuenta, id_beneficiario):
    # Eliminacion logica. El procedimiento pone flagActivo en 0 y guarda
    # la fecha de desactivacion, sin borrar la fila.
    error = validarAcceso(numero_cuenta)
    if error:
        return error
    try:
        ejecutarSpEscritura("dbo.SpEliminarBeneficiario", numero_cuenta, id_beneficiario)
        return jsonify({"ok": True})
    except pyodbc.Error:
        app.logger.exception("Error al eliminar beneficiario")
        return jsonify({"ok": False}), 500


if __name__ == "__main__":
    # Abre el navegador en la pagina de login y levanta el servidor
    webbrowser.open("http://localhost:5000")
    app.run(port=5000)