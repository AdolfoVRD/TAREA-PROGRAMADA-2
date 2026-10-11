USE CuentaAhorro;
SET XACT_ABORT ON;
DECLARE @xml XML;
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\Users\smchi\OneDrive\Documentos\GitHub\TAREA-PROGRAMADA-2\pruebas\no_catalogos.xml', SINGLE_BLOB) AS temp;
BEGIN TRAN;

INSERT INTO dbo.Persona (TipoDocuIdentidad, Nombre, ValorDocumentoIdentidad, FechaNacimiento, Email, telefono1, telefono2)
SELECT
    persona.value('@TipoDocuIdentidad', 'INT'),
    persona.value('@Nombre', 'VARCHAR(64)'),
    persona.value('@ValorDocumentoIdentidad', 'VARCHAR(32)'),
    persona.value('@FechaNacimiento', 'DATE'),
    persona.value('@Email', 'VARCHAR(128)'),
    persona.value('@telefono1', 'VARCHAR(32)'),
    persona.value('@telefono2', 'VARCHAR(32)')
FROM @xml.nodes('/NoCatalogos/Personas/Persona') AS tablaPersonas(persona);

INSERT INTO dbo.Cuenta (IdPersona, TipoCuentaId, NumeroCuenta, FechaCreacion, Saldo)
SELECT
    dueno.IdPersona,
    cuenta.value('@TipoCuentaId', 'INT'),
    cuenta.value('@NumeroCuenta', 'VARCHAR(64)'),
    cuenta.value('@FechaCreacion', 'DATE'),
    cuenta.value('@Saldo', 'DECIMAL(12,2)')
FROM @xml.nodes('/NoCatalogos/Cuentas/Cuenta') AS tablaCuentas(cuenta)
JOIN dbo.Persona dueno
    ON dueno.ValorDocumentoIdentidad = cuenta.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)');

INSERT INTO dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario, IdParentezco, Porcentaje)
SELECT
    beneficiario.value('@NumeroCuenta', 'VARCHAR(64)'),
    beneficiario.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)'),
    beneficiario.value('@IdParentezco', 'INT'),
    beneficiario.value('@Porcentaje', 'DECIMAL(5,2)')
FROM @xml.nodes('/NoCatalogos/Beneficiarios/Beneficiario') AS tablaBeneficiarios(beneficiario);

INSERT INTO dbo.Estado_de_Cuenta (NumeroCuenta, fechaInicio, fechafin, saldoinicial, saldoMinimo, saldo_final,interesesAcumulados, cantRetiros, cantDepositos, cantSinpeEntrantes, cantSinpeSalientes)
SELECT
    estado.value('@NumeroCuenta', 'VARCHAR(64)'),
    estado.value('@fechaInicio', 'DATE'),
    estado.value('@fechafin', 'DATE'),
    estado.value('@saldoinicial', 'DECIMAL(12,2)'),
    estado.value('@saldoMinimo', 'DECIMAL(12,2)'),
    estado.value('@saldo_final', 'DECIMAL(12,2)'),
    estado.value('@interesesAcumulados', 'DECIMAL(12,2)'),
    estado.value('@cantRetiros', 'INT'),
    estado.value('@cantDepositos', 'INT'),
    estado.value('@cantSinpeEntrantes', 'INT'),
    estado.value('@cantSinpeSalientes', 'INT')
FROM @xml.nodes('/NoCatalogos/Estados_de_Cuenta/Estado_de_Cuenta') AS tablaEstados(estado);

INSERT INTO dbo.Usuario (User_, Pass, EsAdministrador, ValorDocId)
SELECT
    usuario.value('@User', 'VARCHAR(32)'),
    usuario.value('@Pass', 'VARCHAR(32)'),
    usuario.value('@EsAdministrador', 'BIT'),
    usuario.value('@ValorDocId', 'VARCHAR(32)')
FROM @xml.nodes('/NoCatalogos/Usuarios/Usuario') AS tablaUsuarios(usuario);

INSERT INTO dbo.Usuarios_Ver (User_, NumeroCuenta)
SELECT
    permiso.value('@User', 'VARCHAR(32)'),
    permiso.value('@NumeroCuenta', 'VARCHAR(64)')
FROM @xml.nodes('/NoCatalogos/Usuarios_Ver/UsuarioPuedeVer') AS tablaPermisos(permiso);

COMMIT;