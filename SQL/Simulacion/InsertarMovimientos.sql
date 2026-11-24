USE CuentaAhorro;
GO
CREATE OR ALTER PROCEDURE dbo.SpInsertarMovimiento
    @NumeroCuenta VARCHAR(64),
    @IdTipoMovimiento INT,
    @Fecha DATE,
    @Monto DECIMAL(12,2),
    @Descripcion NVARCHAR(256),
    @PermitirNegativo BIT,
    @Aplicado BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Aplicado = 0;

    DECLARE @Accion VARCHAR(8);
    DECLARE @NombreTipo VARCHAR(64);
    DECLARE @Saldo DECIMAL(12,2);
    DECLARE @NuevoSaldo DECIMAL(12,2);
    DECLARE @IdEstadoCuenta INT;

    SELECT @Accion = tipo.Accion, @NombreTipo = tipo.Nombre
    FROM dbo.Tipos_Movimiento tipo
    WHERE tipo.Id = @IdTipoMovimiento;

    IF @Accion IS NULL OR @Monto <= 0 RETURN;

    SELECT @Saldo = cuenta.Saldo
    FROM dbo.Cuenta cuenta 
    WHERE cuenta.NumeroCuenta = @NumeroCuenta;

    IF @Saldo IS NULL RETURN;

    SET @NuevoSaldo = CASE WHEN @Accion = 'Credito' THEN @Saldo + @Monto ELSE @Saldo - @Monto END;

    -- Un movimiento del cliente no puede dejar el saldo negativo
    IF @NuevoSaldo < 0 AND @PermitirNegativo = 0 RETURN;

    SELECT @IdEstadoCuenta = estado.IdEstadoCuenta
    FROM dbo.Estado_de_Cuenta estado
    WHERE estado.NumeroCuenta = @NumeroCuenta AND estado.EstaAbierto = 1;

    IF @IdEstadoCuenta IS NULL RETURN;
    -- Actualiza el saldo de la cuenta y del estado de cuenta, y registra el movimiento
    UPDATE dbo.Cuenta
    SET Saldo = @NuevoSaldo
    WHERE NumeroCuenta = @NumeroCuenta;

    UPDATE dbo.Estado_de_Cuenta
    SET saldo_final = @NuevoSaldo,
        saldoMinimo = CASE
            -- Primer movimiento de un estado que empezó en cero
            WHEN saldoinicial = 0
                 AND NOT EXISTS (SELECT 1 FROM dbo.Movimiento WHERE IdEstadoCuenta = @IdEstadoCuenta)
                THEN @NuevoSaldo
            WHEN @NuevoSaldo < saldoMinimo THEN @NuevoSaldo
            ELSE saldoMinimo
        END,
        cantOpATM = cantOpATM + CASE WHEN @NombreTipo = 'Retiro ATM' THEN 1 ELSE 0 END,
        cantOpHumano = cantOpHumano + CASE WHEN @NombreTipo = 'Retiro Ventana' THEN 1 ELSE 0 END,
        cantOpSinpe = cantOpSinpe + CASE WHEN @NombreTipo IN ('Deposito Sinpe', 'Retiro Sinpe') THEN 1 ELSE 0 END
    WHERE IdEstadoCuenta = @IdEstadoCuenta;

    INSERT INTO dbo.Movimiento (NumeroCuenta, IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto, Descripcion, NuevoSaldo)
    VALUES (@NumeroCuenta, @IdEstadoCuenta, @IdTipoMovimiento, @Fecha, @Monto, @Descripcion, @NuevoSaldo);

    SET @Aplicado = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpAplicarMovimiento
    @NumeroCuenta VARCHAR(64),
    @NombreTipo VARCHAR(64),
    @Fecha DATE,
    @Monto DECIMAL(12,2),
    @Descripcion NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdTipo INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = @NombreTipo);
    IF @IdTipo IS NULL RETURN;

    -- Si ya hay una transacción abierta (la de la simulación) no abre otra
    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Aplicado BIT;

    BEGIN TRY
        IF @Propia = 1 BEGIN TRAN;

        EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdTipo, @Fecha, @Monto, @Descripcion, 0, @Aplicado OUTPUT;

        IF @Aplicado = 1 AND @NombreTipo = 'Retiro Sinpe'
        BEGIN
            DECLARE @MontoMaxSinpe DECIMAL(12,2);
            DECLARE @ComisionSinpe DECIMAL(12,2);
            DECLARE @TotalSinpeHoy DECIMAL(12,2);
            DECLARE @IdComision INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = 'Comision Sinpe');

            SELECT @MontoMaxSinpe = tipoCuenta.MontoMaxSinpeDiario,
                   @ComisionSinpe = tipoCuenta.ComisionSinpe
            FROM dbo.Cuenta cuenta
            JOIN dbo.Tipo_Cuenta_Ahorros tipoCuenta ON tipoCuenta.Id = cuenta.TipoCuentaId
            WHERE cuenta.NumeroCuenta = @NumeroCuenta;

            SELECT @TotalSinpeHoy = SUM(movimiento.Monto)
            FROM dbo.Movimiento movimiento
            WHERE movimiento.NumeroCuenta = @NumeroCuenta
              AND movimiento.Fecha = @Fecha
              AND movimiento.IdTipoMovimiento = @IdTipo;

            IF @TotalSinpeHoy > @MontoMaxSinpe
                EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdComision, @Fecha, @ComisionSinpe,
                     N'Comisión por exceder el límite diario de Sinpe', 1, @Aplicado OUTPUT;
        END

        IF @Propia = 1 COMMIT;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO