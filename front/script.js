const API_URL = "http://localhost:5000";


function CargarMenu() {
    const usuarioGuardado = sessionStorage.getItem("usuario");
    const esAdmin = sessionStorage.getItem("esAdmin");
    const valorDocId = sessionStorage.getItem("valorDocId");
    console.log("Valor Doc ID:", valorDocId);
    console.log("Usuario guardado:", usuarioGuardado);
    console.log("Es administrador:", esAdmin);
    if (!usuarioGuardado) {
        
        window.location.href = "index.html";
        return;
    }

    const usuario = usuarioGuardado;

    const nombreUsuarioElement = document.getElementById("nombreUsuario");
    if (nombreUsuarioElement) {
        nombreUsuarioElement.textContent = usuario;
    }
}

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
            if (data.mensaje === "Se ha iniciado sesión correctamente") {
                sessionStorage.setItem("usuario", data.usuario);
                sessionStorage.setItem("esAdmin", String(data.esAdministrador));
                sessionStorage.setItem("valorDocId", String(data.valorDocId));
                window.location.href = "menu.html";
            }
        })
        .catch(error => {
            console.error("Error al iniciar sesión:", error);
            mensaje.textContent = "Error al iniciar sesión." + (error.message ? ` ${error.message}` : "");
        })
        .finally(() => {
            usuarioInput.value = "";
            contraseñaInput.value = "";
        });
}

function CargarBeneficiarios(numeroCuenta) {
    const tabla = document.getElementById("tablaBeneficiarios");
    tabla.innerHTML = "";
    fetch(`${API_URL}/beneficiarios/${numeroCuenta}`)
        .then(response => response.json())
        .then(beneficiarios => {
            beneficiarios.forEach(beneficiario => {
                const fila = document.createElement("tr");
                fila.innerHTML = `
                    <td>${beneficiario.nombre}</td>
                    <td>${beneficiario.porcentaje}</td>
                `;
                tabla.appendChild(fila);
            });
        })
        .catch(() => {
            mensaje.textContent = "No se pudieron cargar los beneficiarios.";
        });
}

function cargarEstados(numeroCuenta) {
            mensaje.textContent = "";
            tablaEstados.innerHTML = "";
            fetch(`${API_URL}/estados/${numeroCuenta}`)
                .then(response => response.json())
                .then(estados => {
                    estados.forEach(estado => {
                        const fila = document.createElement("tr");
                        fila.style.cursor = "pointer";
                        fila.innerHTML = `
                            <td>${estado.fechaEstado}</td>
                            <td>${dinero(estado.saldoInicial)}</td>
                            <td>${dinero(estado.saldoFinal)}</td>
                            <td>${dinero(estado.saldoMinimo)}</td>
                            <td>${dinero(estado.intereses)}</td>
                            <td>${estado.retiros}</td>
                            <td>${estado.depositos}</td>
                            <td>${estado.sinpeEntrantes}</td>
                            <td>${estado.sinpeSalientes}</td>`;
                        fila.addEventListener("click", () => {
                            // En la TP3 aquí se mostrarán los movimientos del mes
                        });
                        tablaEstados.appendChild(fila);
                    });
                })
                .catch(() => {
                    mensaje.textContent = "No se pudieron cargar los estados de cuenta.";
                });
        }