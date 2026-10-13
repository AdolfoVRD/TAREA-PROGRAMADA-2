USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarUsuarios
AS 
BEGIN

    SELECT 
        IdUsuario,
        User_,
        Pass,
        EsAdministrador,
        ValorDocId
    FROM 
        dbo.Usuario
END;
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarBeneficiarios
@CuentaID VARCHAR(64)
AS
BEGIN 
    SELECT 
        IdBeneficiario,
        NumeroCuenta,
        ValorDocumentoIdentidadBeneficiario,
        IdParentezco,
        Porcentaje
    FROM
        dbo.Beneficiario
    WHERE NumeroCuenta = @CuentaID
END;
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarPersonasDocId
@DocID VARCHAR(32)
AS
BEGIN
    SELECT 
        Nombre,
        IdPersona,
        FechaNacimiento,
        Email,
        telefono1,
        telefono2
    FROM
        dbo.Persona
    WHERE ValorDocumentoIdentidad = @DocID
END;
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarValorDocIDPersona
@ValorDocID VARCHAR(32)
AS
BEGIN
    SELECT 
        IdPersona,
        Nombre,
        FechaNacimiento,
        Email,
        telefono1,
        telefono2
    FROM
        dbo.Persona
    WHERE ValorDocumentoIdentidad = @ValorDocID
END;
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarCuentasIdPersona
@IdPersona INT
AS 
BEGIN
    SELECT 
        NumeroCuenta,
        IdPersona,
        Saldo
    FROM
        dbo.Cuenta
    WHERE IdPersona = @IdPersona
END;
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarPersonasIdPersona
@IdPersona INT
AS
BEGIN
    SELECT 
        Nombre,
        IdPersona,
        FechaNacimiento,
        Email,
        telefono1,
        telefono2
    FROM
        dbo.Persona
    WHERE IdPersona = @IdPersona
END;

Create OR ALTER PROCEDURE dbo.SpConsultarCuentasPersonaId
@IdPersona INT
AS
BEGIN
    SELECT 
        IdCuenta,
        NumeroCuenta,
        TipoCuentaId,  
        FechaCreacion, 
        IdPersona,
        Saldo
    FROM
        dbo.Cuenta
    WHERE IdPersona = @IdPersona

END;