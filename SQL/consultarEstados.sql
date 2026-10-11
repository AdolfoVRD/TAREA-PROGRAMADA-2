GO
USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpLogin
    @User VARCHAR(32),
    @Pass VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT User_, EsAdministrador
    FROM dbo.Usuario
    WHERE User_ = @User AND Pass = @Pass;
END
GO
USE CuentaAhorro;
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarCuentasUsuario
    @User VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EsAdmin BIT = ISNULL((SELECT EsAdministrador FROM dbo.Usuario WHERE User_ = @User), 0);
    SELECT c.NumeroCuenta
    FROM dbo.Cuenta c
    WHERE @EsAdmin = 1
       OR c.NumeroCuenta IN (SELECT NumeroCuenta FROM dbo.Usuarios_Ver WHERE User_ = @User)
    ORDER BY c.NumeroCuenta;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarEstadosCuenta
    @User VARCHAR(32),
    @NumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EsAdmin BIT = ISNULL((SELECT EsAdministrador FROM dbo.Usuario WHERE User_ = @User), 0);
    SELECT TOP 8
           e.NumeroCuenta, e.fechaInicio, e.fechafin, e.saldoinicial, e.saldo_final,
           e.saldoMinimo, e.interesesAcumulados, e.cantRetiros, e.cantDepositos,
           e.cantSinpeEntrantes, e.cantSinpeSalientes
    FROM dbo.Estado_de_Cuenta e
    WHERE e.NumeroCuenta = @NumeroCuenta
      AND (@EsAdmin = 1 OR EXISTS (SELECT 1 FROM dbo.Usuarios_Ver uv WHERE uv.User_ = @User AND uv.NumeroCuenta = @NumeroCuenta))
    ORDER BY e.fechafin DESC;
END
