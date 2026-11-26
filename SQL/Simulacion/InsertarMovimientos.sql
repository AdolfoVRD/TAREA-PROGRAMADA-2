USE CuentaAhorro;
GO
CREATE OR ALTER PROCEDURE dbo.SpInsertarMovimiento
    @inNumeroCuenta VARCHAR(64),
    @inIdTipoMovimiento INT,
    @inFecha DATE,
    @inMonto DECIMAL(12,2),
    @inDescripcion NVARCHAR(256),
    @inPermitirNegativo BIT,
    @outAplicado BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @outAplicado = 0;

        DECLARE @Accion VARCHAR(8);
        DECLARE @NombreTipo VARCHAR(64);
        DECLARE @Saldo DECIMAL(12,2);
        DECLARE @NuevoSaldo DECIMAL(12,2);
        DECLARE @IdEstadoCuenta INT;

        SELECT @Accion = tipo.Accion, @NombreTipo = tipo.Nombre
        FROM dbo.Tipos_Movimiento tipo
        WHERE tipo.Id = @inIdTipoMovimiento;

        IF @Accion IS NULL OR @inMonto <= 0 RETURN;

        SELECT @Saldo = cuenta.Saldo
        FROM dbo.Cuenta cuenta 
        WHERE cuenta.NumeroCuenta = @inNumeroCuenta;

        IF @Saldo IS NULL RETURN;

        SET @NuevoSaldo = CASE WHEN @Accion = 'Credito' THEN @Saldo + @inMonto ELSE @Saldo - @inMonto END;

        -- Un movimiento del cliente no puede dejar el saldo negativo
        IF @NuevoSaldo < 0 AND @inPermitirNegativo = 0 RETURN;

        SELECT @IdEstadoCuenta = estado.IdEstadoCuenta
        FROM dbo.Estado_de_Cuenta estado
        WHERE estado.NumeroCuenta = @inNumeroCuenta AND estado.EstaAbierto = 1;

        IF @IdEstadoCuenta IS NULL RETURN;
        -- Actualiza el saldo de la cuenta y del estado de cuenta, y registra el movimiento
        UPDATE dbo.Cuenta
        SET Saldo = @NuevoSaldo
        WHERE NumeroCuenta = @inNumeroCuenta;

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
        VALUES (@inNumeroCuenta, @IdEstadoCuenta, @inIdTipoMovimiento, @inFecha, @inMonto, @inDescripcion, @NuevoSaldo);

        SET @outAplicado = 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.SpAplicarMovimiento
    @inNumeroCuenta VARCHAR(64),
    @inNombreTipo VARCHAR(64),
    @inFecha DATE,
    @inMonto DECIMAL(12,2),
    @inDescripcion NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdTipo INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = @inNombreTipo);
    IF @IdTipo IS NULL RETURN;

    -- Si ya hay una transacción abierta (la de la simulación) no abre otra
    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Aplicado BIT;

    BEGIN TRY
        IF @Propia = 1 BEGIN TRAN;

        EXEC dbo.SpInsertarMovimiento @inNumeroCuenta, @IdTipo, @inFecha, @inMonto, @inDescripcion, 0, @Aplicado OUTPUT;

        IF @Aplicado = 1 AND @inNombreTipo = 'Retiro Sinpe'
        BEGIN
            DECLARE @MontoMaxSinpe DECIMAL(12,2);
            DECLARE @ComisionSinpe DECIMAL(12,2);
            DECLARE @TotalSinpeHoy DECIMAL(12,2);
            DECLARE @IdComision INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = 'Comision Sinpe');

            SELECT @MontoMaxSinpe = tipoCuenta.MontoMaxSinpeDiario,
                   @ComisionSinpe = tipoCuenta.ComisionSinpe
            FROM dbo.Cuenta cuenta
            JOIN dbo.Tipo_Cuenta_Ahorros tipoCuenta ON tipoCuenta.Id = cuenta.TipoCuentaId
            WHERE cuenta.NumeroCuenta = @inNumeroCuenta;

            SELECT @TotalSinpeHoy = SUM(movimiento.Monto)
            FROM dbo.Movimiento movimiento
            WHERE movimiento.NumeroCuenta = @inNumeroCuenta
              AND movimiento.Fecha = @inFecha
              AND movimiento.IdTipoMovimiento = @IdTipo;

            IF @TotalSinpeHoy > @MontoMaxSinpe
                EXEC dbo.SpInsertarMovimiento @inNumeroCuenta, @IdComision, @inFecha, @ComisionSinpe,
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