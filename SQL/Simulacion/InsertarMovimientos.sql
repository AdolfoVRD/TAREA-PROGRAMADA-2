USE CuentaAhorro;
GO
CREATE OR ALTER PROCEDURE dbo.SpInsertarMovimiento
    @InNumeroCuenta VARCHAR(64),
    @InIdTipoMovimiento INT,
    @InFecha DATE,
    @InMonto DECIMAL(12,2),
    @InDescripcion NVARCHAR(256),
    @InPermitirNegativo BIT,
    @InAplicado BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @InAplicado = 0;

    DECLARE @Accion VARCHAR(8);
    DECLARE @NombreTipo VARCHAR(64);
    DECLARE @Saldo DECIMAL(12,2);
    DECLARE @NuevoSaldo DECIMAL(12,2);
    DECLARE @IdEstadoCuenta INT;

    SELECT @Accion = tipo.Accion, @NombreTipo = tipo.Nombre
    FROM dbo.Tipos_Movimiento tipo
    WHERE tipo.Id = @InIdTipoMovimiento;

    IF @Accion IS NULL OR @InMonto <= 0 RETURN;

    SELECT @Saldo = cuenta.Saldo
    FROM dbo.Cuenta cuenta 
    WHERE cuenta.NumeroCuenta = @InNumeroCuenta;

    IF @Saldo IS NULL RETURN;

    SET @NuevoSaldo = CASE WHEN @Accion = 'Credito' THEN @Saldo + @InMonto ELSE @Saldo - @InMonto END;

    -- Un movimiento del cliente no puede dejar el saldo negativo
    IF @NuevoSaldo < 0 AND @InPermitirNegativo = 0 RETURN;

    SELECT @IdEstadoCuenta = estado.IdEstadoCuenta
    FROM dbo.Estado_de_Cuenta estado
    WHERE estado.NumeroCuenta = @InNumeroCuenta AND estado.EstaAbierto = 1;

    IF @IdEstadoCuenta IS NULL RETURN;
    -- Actualiza el saldo de la cuenta y del estado de cuenta, y registra el movimiento
    UPDATE dbo.Cuenta
    SET Saldo = @InNuevoSaldo
    WHERE NumeroCuenta = @InNumeroCuenta;

    UPDATE dbo.Estado_de_Cuenta
    SET saldo_final = @InNuevoSaldo,
        saldoMinimo = CASE
            -- Primer movimiento de un estado que empezó en cero
            WHEN saldoinicial = 0
                 AND NOT EXISTS (SELECT 1 FROM dbo.Movimiento WHERE IdEstadoCuenta = @IdEstadoCuenta)
                THEN @InNuevoSaldo
            WHEN @InNuevoSaldo < saldoMinimo THEN @InNuevoSaldo
            ELSE saldoMinimo
        END,
        cantOpATM = cantOpATM + CASE WHEN @InNombreTipo = 'Retiro ATM' THEN 1 ELSE 0 END,
        cantOpHumano = cantOpHumano + CASE WHEN @InNombreTipo = 'Retiro Ventana' THEN 1 ELSE 0 END,
        cantOpSinpe = cantOpSinpe + CASE WHEN @InNombreTipo IN ('Deposito Sinpe', 'Retiro Sinpe') THEN 1 ELSE 0 END
    WHERE IdEstadoCuenta = @IdEstadoCuenta;

    INSERT INTO dbo.Movimiento (NumeroCuenta, IdEstadoCuenta, IdTipoMovimiento, Fecha, Monto, Descripcion, NuevoSaldo)
    VALUES (@InNumeroCuenta, @IdEstadoCuenta, @InIdTipoMovimiento, @InFecha, @InMonto, @InDescripcion, @InNuevoSaldo);

    SET @InAplicado = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpAplicarMovimiento
    @InNumeroCuenta VARCHAR(64),
    @InNombreTipo VARCHAR(64),
    @InFecha DATE,
    @InMonto DECIMAL(12,2),
    @InDescripcion NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @IdTipo INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = @InNombreTipo);
    IF @IdTipo IS NULL RETURN;

    -- Si ya hay una transacción abierta (la de la simulación) no abre otra
    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Aplicado BIT;

    BEGIN TRY
        IF @Propia = 1 BEGIN TRAN;

        EXEC dbo.SpInsertarMovimiento @InNumeroCuenta, @IdTipo, @InFecha, @InMonto, @InDescripcion, 0, @Aplicado OUTPUT;

        IF @Aplicado = 1 AND @InNombreTipo = 'Retiro Sinpe'
        BEGIN
            DECLARE @MontoMaxSinpe DECIMAL(12,2);
            DECLARE @ComisionSinpe DECIMAL(12,2);
            DECLARE @TotalSinpeHoy DECIMAL(12,2);
            DECLARE @IdComision INT = (SELECT tipo.Id FROM dbo.Tipos_Movimiento tipo WHERE tipo.Nombre = 'Comision Sinpe');

            SELECT @MontoMaxSinpe = tipoCuenta.MontoMaxSinpeDiario,
                   @ComisionSinpe = tipoCuenta.ComisionSinpe
            FROM dbo.Cuenta cuenta
            JOIN dbo.Tipo_Cuenta_Ahorros tipoCuenta ON tipoCuenta.Id = cuenta.TipoCuentaId
            WHERE cuenta.NumeroCuenta = @InNumeroCuenta;

            SELECT @TotalSinpeHoy = SUM(movimiento.Monto)
            FROM dbo.Movimiento movimiento
            WHERE movimiento.NumeroCuenta = @InNumeroCuenta
              AND movimiento.Fecha = @InFecha
              AND movimiento.IdTipoMovimiento = @IdTipo;

            IF @TotalSinpeHoy > @MontoMaxSinpe
                EXEC dbo.SpInsertarMovimiento @InNumeroCuenta, @IdComision, @InFecha, @ComisionSinpe,
                     N'Comisión por exceder el límite diario de Sinpe', 1, @InAplicado OUTPUT;
        END

        IF @Propia = 1 COMMIT;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO