USE CuentaAhorro;
GO
CREATE OR ALTER PROCEDURE dbo.SpCerrarEstadoCuenta
    @InIdEstadoCuenta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NumeroCuenta VARCHAR(64);
    DECLARE @FechaCreacion DATE;
    DECLARE @FechaFin DATE;
    DECLARE @SaldoMinimo DECIMAL(12,2);
    DECLARE @CantATM INT;
    DECLARE @CantHumano INT;
    DECLARE @SaldoMinPermitido DECIMAL(12,2);
    DECLARE @Multa DECIMAL(12,2);
    DECLARE @CargoMensual DECIMAL(12,2);
    DECLARE @MaxHumano INT;
    DECLARE @MaxATM INT;
    DECLARE @ComisionHumano DECIMAL(12,2);
    DECLARE @ComisionATM DECIMAL(12,2);
    DECLARE @Tasa DECIMAL(5,2);

    SELECT @NumeroCuenta = estado.NumeroCuenta,
           @FechaCreacion = cuenta.FechaCreacion,
           @FechaFin = estado.fechafin,
           @SaldoMinimo = estado.saldoMinimo,
           @CantATM = estado.cantOpATM,
           @CantHumano = estado.cantOpHumano,
           @SaldoMinPermitido = tipoCuenta.SaldoMinimo,
           @Multa = tipoCuenta.MultaSaldoMin,
           @CargoMensual = tipoCuenta.CargoMensual,
           @MaxHumano = tipoCuenta.NumRetirosHumano,
           @MaxATM = tipoCuenta.NumRetirosAutomatico,
           @ComisionHumano = tipoCuenta.ComisionHumano,
           @ComisionATM = tipoCuenta.ComisionAutomatico,
           @Tasa = tipoCuenta.TasaInteresAnual
    FROM dbo.Estado_de_Cuenta estado
    JOIN dbo.Cuenta cuenta ON cuenta.NumeroCuenta = estado.NumeroCuenta
    JOIN dbo.Tipo_Cuenta_Ahorros tipoCuenta ON tipoCuenta.Id = cuenta.TipoCuentaId
    WHERE estado.IdEstadoCuenta = @InIdEstadoCuenta AND estado.EstaAbierto = 1;

    IF @NumeroCuenta IS NULL RETURN;

    DECLARE @IdInteres INT = (SELECT Id FROM dbo.Tipos_Movimiento WHERE Nombre = 'Intereses Mensuales');
    DECLARE @IdComisionATM INT = (SELECT Id FROM dbo.Tipos_Movimiento WHERE Nombre = 'Comision Exceso ATM');
    DECLARE @IdComisionHumano INT = (SELECT Id FROM dbo.Tipos_Movimiento WHERE Nombre = 'Comision Exceso Ventana');
    DECLARE @IdMulta INT = (SELECT Id FROM dbo.Tipos_Movimiento WHERE Nombre = 'Multa Saldo Minimo');
    DECLARE @IdCargo INT = (SELECT Id FROM dbo.Tipos_Movimiento WHERE Nombre = 'Cargo Servicio Mensual');

    DECLARE @Propia BIT = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END;
    DECLARE @Aplicado BIT;
    DECLARE @Monto DECIMAL(12,2);

    BEGIN TRY
        IF @Propia = 1 BEGIN TRANSACTION;

        -- Intereses sobre el saldo mínimo, tasa anual dividida entre 12
        SET @Monto = CAST(ROUND(@SaldoMinimo * @Tasa / 100.0 / 12.0, 2) AS DECIMAL(12,2));
        IF @Monto > 0
            EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdInteres, @FechaFin, @Monto,
                 N'Intereses mensuales', 1, @Aplicado OUTPUT;

        -- Exceso de operaciones en cajero automático
        IF @CantATM > @MaxATM
        BEGIN
            SET @Monto = (@CantATM - @MaxATM) * @ComisionATM;
            EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdComisionATM, @FechaFin, @Monto,
                 N'Comisión por exceso de operaciones en cajero automático', 1, @Aplicado OUTPUT;
        END

        -- Exceso de operaciones en ventana
        IF @CantHumano > @MaxHumano
        BEGIN
            SET @Monto = (@CantHumano - @MaxHumano) * @ComisionHumano;
            EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdComisionHumano, @FechaFin, @Monto,
                 N'Comisión por exceso de operaciones en ventana', 1, @Aplicado OUTPUT;
        END

        -- Multa si el saldo estuvo por debajo del mínimo permitido
        IF @SaldoMinimo < @SaldoMinPermitido
            EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdMulta, @FechaFin, @Multa,
                 N'Multa por saldo mínimo', 1, @Aplicado OUTPUT;

        -- Cargo por servicio
        EXEC dbo.SpInsertarMovimiento @NumeroCuenta, @IdCargo, @FechaFin, @CargoMensual,
             N'Cargo por servicio mensual', 1, @Aplicado OUTPUT;

        -- Cierra el estado actual
        UPDATE dbo.Estado_de_Cuenta
        SET EstaAbierto = 0
        WHERE IdEstadoCuenta = @InIdEstadoCuenta;

        -- Abre el siguiente
        DECLARE @SaldoActual DECIMAL(12,2) = (SELECT Saldo FROM dbo.Cuenta WHERE NumeroCuenta = @NumeroCuenta);
        DECLARE @NuevoInicio DATE = DATEADD(DAY, 1, @FechaFin);
        DECLARE @NuevoFin DATE = DATEADD(MONTH, DATEDIFF(MONTH, @FechaCreacion, @FechaFin) + 1, @FechaCreacion);

        INSERT INTO dbo.Estado_de_Cuenta (NumeroCuenta, fechaInicio, fechafin, saldoinicial, saldoMinimo, saldo_final)
        VALUES (@NumeroCuenta, @NuevoInicio, @NuevoFin, @SaldoActual, @SaldoActual, @SaldoActual);

        IF @Propia = 1 COMMIT;
    END TRY
    BEGIN CATCH
        IF @Propia = 1 AND @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO