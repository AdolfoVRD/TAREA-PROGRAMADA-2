USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpLogin
    @User VARCHAR(32),
    @Pass VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT usuario.IdUsuario,
           usuario.User_,
           usuario.EsAdministrador,
           usuario.ValorDocId
    FROM dbo.Usuario usuario
    WHERE usuario.User_ = @User
      AND usuario.Pass = @Pass;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarCuentasUsuario
    @User VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EsAdministrador BIT = ISNULL(
        (SELECT usuario.EsAdministrador
         FROM dbo.Usuario usuario
         WHERE usuario.User_ = @User), 0);
    SELECT cuenta.NumeroCuenta
    FROM dbo.Cuenta cuenta
    WHERE @EsAdministrador = 1 
    OR cuenta.NumeroCuenta 
    IN (SELECT usuarioVer.NumeroCuenta FROM dbo.Usuarios_Ver usuarioVer WHERE usuarioVer.User_ = @User)
    ORDER BY cuenta.NumeroCuenta;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarEstadosCuenta
    @User VARCHAR(32),
    @NumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EsAdministrador BIT = ISNULL(
        (SELECT usuario.EsAdministrador
         FROM dbo.Usuario usuario
         WHERE usuario.User_ = @User), 0);

    SELECT TOP 8
           estadoCuenta.NumeroCuenta,
           estadoCuenta.fechaInicio,
           estadoCuenta.fechafin,
           estadoCuenta.saldoinicial,
           estadoCuenta.saldo_final,
           estadoCuenta.saldoMinimo,
           estadoCuenta.interesesAcumulados,
           estadoCuenta.cantRetiros,
           estadoCuenta.cantDepositos,
           estadoCuenta.cantSinpeEntrantes,
           estadoCuenta.cantSinpeSalientes
    FROM dbo.Estado_de_Cuenta estadoCuenta
    WHERE estadoCuenta.NumeroCuenta = @NumeroCuenta
      AND (@EsAdministrador = 1
           OR EXISTS (SELECT 1
                      FROM dbo.Usuarios_Ver usuarioVer
                      WHERE usuarioVer.User_ = @User
                        AND usuarioVer.NumeroCuenta = @NumeroCuenta))
    ORDER BY estadoCuenta.fechafin DESC;
END
GO