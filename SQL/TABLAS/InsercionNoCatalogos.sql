USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpCargarEntidadesDia
    @xml XML,
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Se queda solo con el nodo de la fecha pedida
    DECLARE @FechaTexto VARCHAR(10) = CONVERT(VARCHAR(10), @Fecha, 23);
    DECLARE @dia XML = @xml.query('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaTexto")]');

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
    FROM @dia.nodes('/FechaOperacion/Persona') AS tablaPersonas(persona);

    -- El trigger abre el primer estado de cuenta en cada insercion
    INSERT INTO dbo.Cuenta (IdPersona, TipoCuentaId, NumeroCuenta, FechaCreacion, Saldo)
    SELECT
        dueno.IdPersona,
        cuenta.value('@TipoCuentaId', 'INT'),
        cuenta.value('@NumeroCuenta', 'VARCHAR(64)'),
        cuenta.value('@FechaCreacion', 'DATE'),
        cuenta.value('@Saldo', 'DECIMAL(12,2)')
    FROM @dia.nodes('/FechaOperacion/Cuenta') AS tablaCuentas(cuenta)
    JOIN dbo.Persona dueno
        ON dueno.ValorDocumentoIdentidad = cuenta.value('@ValorDocumentoIdentidadDelCliente', 'VARCHAR(32)');

    INSERT INTO dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario, IdParentezco, Porcentaje)
    SELECT
        beneficiario.value('@NumeroCuenta', 'VARCHAR(64)'),
        beneficiario.value('@ValorDocumentoIdentidadBeneficiario', 'VARCHAR(32)'),
        beneficiario.value('@IdParentezco', 'INT'),
        beneficiario.value('@Porcentaje', 'DECIMAL(5,2)')
    FROM @dia.nodes('/FechaOperacion/Beneficiario') AS tablaBeneficiarios(beneficiario);

    INSERT INTO dbo.Usuario (User_, Pass, EsAdministrador, ValorDocId)
    SELECT
        usuario.value('@User', 'VARCHAR(32)'),
        usuario.value('@Pass', 'VARCHAR(32)'),
        usuario.value('@EsAdministrador', 'BIT'),
        usuario.value('@ValorDocId', 'VARCHAR(32)')
    FROM @dia.nodes('/FechaOperacion/Usuario') AS tablaUsuarios(usuario);

    INSERT INTO dbo.Usuarios_Ver (User_, NumeroCuenta)
    SELECT
        permiso.value('@User', 'VARCHAR(32)'),
        permiso.value('@NumeroCuenta', 'VARCHAR(64)')
    FROM @dia.nodes('/FechaOperacion/UsuarioPuedeVer') AS tablaPermisos(permiso);

    COMMIT;
END
GO