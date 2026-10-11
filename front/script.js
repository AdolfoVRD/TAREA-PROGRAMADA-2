const API_URL = "http://localhost:5000";

function iniciarSesion(event) {
    event.preventDefault();

    const usuarioInput = document.getElementById("inputUsuario");
    const contraseñaInput = document.getElementById("inputContraseña");
    const mensaje = document.getElementById("mensaje");
    const usuario = usuarioInput.value.trim();
    const contraseña = contraseñaInput.value;

    mensaje.textContent = "";

    if (!usuario || !contraseña) {
        mensaje.textContent = "Ingrese el usuario y la contraseña.";
        return;
    }

    console.info("Enviando solicitud de inicio de sesión.");

    fetch(`${API_URL}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ nombre: usuario, contraseña: contraseña })
    })
        .then(async response => {
            const data = await response.json();
            if (!response.ok) {
                throw new Error(data.mensaje || "No se pudo iniciar sesión.");
            }
            return data;
        })
        .then(data => {
            console.log(data.mensaje);
            mensaje.textContent = data.mensaje;
        })
        .catch(error => {
            console.error("Error al iniciar sesión:", error);
            mensaje.textContent = error instanceof TypeError
                ? "No se pudo conectar con el servidor."
                : error.message || "No se pudo iniciar sesión.";
        })
        .finally(() => {
            usuarioInput.value = "";
            contraseñaInput.value = "";
        });
}
