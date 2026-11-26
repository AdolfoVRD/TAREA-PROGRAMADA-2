USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpLogin
    @InUser VARCHAR(32),
    @InPass VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT usuario.IdUsuario,
           usuario.User_,
           usuario.EsAdministrador,
           usuario.ValorDocId
    FROM dbo.Usuario usuario
    WHERE usuario.User_ = @InUser
      AND usuario.Pass = @InPass;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarCuentasUsuario
    @InUser VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EsAdministrador BIT = ISNULL(
        (SELECT usuario.EsAdministrador
         FROM dbo.Usuario usuario
         WHERE usuario.User_ = @InUser), 0);
    SELECT cuenta.NumeroCuenta
    FROM dbo.Cuenta cuenta
    WHERE @EsAdministrador = 1 
    OR cuenta.NumeroCuenta 
    IN (SELECT usuarioVer.NumeroCuenta FROM dbo.Usuarios_Ver usuarioVer WHERE usuarioVer.User_ = @InUser)
    ORDER BY cuenta.NumeroCuenta;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarEstadosCuenta
    @InUser VARCHAR(32),
    @InNumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EsAdministrador BIT = ISNULL(
        (SELECT usuario.EsAdministrador
         FROM dbo.Usuario usuario
         WHERE usuario.User_ = @InUser), 0);

    SELECT TOP 8
           estadoCuenta.IdEstadoCuenta,
           estadoCuenta.NumeroCuenta,
           estadoCuenta.fechaInicio,
           estadoCuenta.fechafin,
           estadoCuenta.saldoinicial,
           estadoCuenta.saldo_final,
           estadoCuenta.saldoMinimo,
           estadoCuenta.cantOpATM,
           estadoCuenta.cantOpHumano,
           estadoCuenta.cantOpSinpe,
           estadoCuenta.EstaAbierto
    FROM dbo.Estado_de_Cuenta estadoCuenta
    WHERE estadoCuenta.NumeroCuenta = @InNumeroCuenta
      AND (@EsAdministrador = 1
           OR EXISTS (SELECT 1
                      FROM dbo.Usuarios_Ver usuarioVer
                      WHERE usuarioVer.User_ = @InUser
                        AND usuarioVer.NumeroCuenta = @InNumeroCuenta))
    ORDER BY estadoCuenta.fechafin DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarMovimientoEstado
    @InUser VARCHAR(32),
    @InIdEstadoCuenta INT
AS
BEGIN
    SET NOCOUNT ON;


    SELECT movimiento.IdMovimiento,
           movimiento.Fecha,
           movimiento.Monto,
           tipo.Nombre AS TipoMovimiento,
           movimiento.Descripcion
    FROM dbo.Movimiento movimiento
    INNER JOIN dbo.Tipos_Movimiento tipo ON movimiento.IdTipoMovimiento = tipo.Id
    WHERE movimiento.IdEstadoCuenta = @InIdEstadoCuenta
      
    ORDER BY movimiento.Fecha DESC;
    

    -- Actualizar la bitácora con la operación de consultar movimientos
    DECLARE @UserId INT;
    SELECT @UserId = usuario.IdUsuario
    FROM dbo.Usuario usuario
    WHERE usuario.User_ = @InUser;

    EXEC dbo.SpActualizarBitacora @UserId, 8;
END
GO