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
