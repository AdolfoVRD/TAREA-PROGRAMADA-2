Use CuentaAhorro;
CREATE PROCEDURE dbo.SpConsultarUsuarios
AS 
BEGIN
    SELECT 
        IdCuenta,
        User_,
        Pass,
        EsAdministrador,
        ValorDocId
    FROM 
        dbo.Usuarios
END;
