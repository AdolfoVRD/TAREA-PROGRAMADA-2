USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpLogin
    @inUser VARCHAR(32),
    @inPass VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT usuario.IdUsuario,
               usuario.User_,
               usuario.EsAdministrador,
               usuario.ValorDocId
        FROM dbo.Usuario usuario
        WHERE usuario.User_ = @inUser
          AND usuario.Pass = @inPass;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarCuentasUsuario
    @inUser VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @EsAdministrador BIT = ISNULL(
            (SELECT usuario.EsAdministrador
             FROM dbo.Usuario usuario
             WHERE usuario.User_ = @inUser), 0);
        SELECT cuenta.NumeroCuenta
        FROM dbo.Cuenta cuenta
        WHERE @EsAdministrador = 1 
        OR cuenta.NumeroCuenta 
        IN (SELECT usuarioVer.NumeroCuenta FROM dbo.Usuarios_Ver usuarioVer WHERE usuarioVer.User_ = @inUser)
        ORDER BY cuenta.NumeroCuenta;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarEstadosCuenta
    @inUser VARCHAR(32),
    @inNumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @EsAdministrador BIT = ISNULL(
            (SELECT usuario.EsAdministrador
             FROM dbo.Usuario usuario
             WHERE usuario.User_ = @inUser), 0);

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
        WHERE estadoCuenta.NumeroCuenta = @inNumeroCuenta
          AND (@EsAdministrador = 1
               OR EXISTS (SELECT 1
                          FROM dbo.Usuarios_Ver usuarioVer
                          WHERE usuarioVer.User_ = @inUser
                            AND usuarioVer.NumeroCuenta = @inNumeroCuenta))
        ORDER BY estadoCuenta.fechafin DESC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarMovimientoEstado
    @inUser VARCHAR(32),
    @inIdEstadoCuenta INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT movimiento.IdMovimiento,
               movimiento.Fecha,
               movimiento.Monto,
               tipo.Nombre AS TipoMovimiento,
               movimiento.Descripcion,
               movimiento.NuevoSaldo
        FROM dbo.Movimiento movimiento
        INNER JOIN dbo.Tipos_Movimiento tipo ON movimiento.IdTipoMovimiento = tipo.Id
        WHERE movimiento.IdEstadoCuenta = @inIdEstadoCuenta
      
        ORDER BY movimiento.Fecha DESC;
    

        -- Actualizar la bitácora con la operación de consultar movimientos
        DECLARE @UserId INT;
        SELECT @UserId = usuario.IdUsuario
        FROM dbo.Usuario usuario
        WHERE usuario.User_ = @inUser;

        EXEC dbo.SpActualizarBitacora @UserId, 8;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO