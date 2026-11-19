USE CuentaAhorro;
SET XACT_ABORT ON;
SET NOCOUNT ON;

DROP TABLE IF EXISTS #MovDia;
DROP TABLE IF EXISTS #Cierres;

DECLARE @xml XML;
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\GitHub\TAREA-PROGRAMADA-2\pruebas\OperacionesTarea3.xml', SINGLE_BLOB) AS temp;

-- Rango de fechas que trae el XML
DECLARE @Fecha DATE;
DECLARE @FechaFin DATE;
SELECT @Fecha = MIN(dia.value('@Fecha', 'DATE')),
       @FechaFin = MAX(dia.value('@Fecha', 'DATE'))
FROM @xml.nodes('/Operaciones/FechaOperacion') AS tablaDias(dia);

-- Si ya hay fechas procesadas, retoma desde la siguiente a la última
DECLARE @UltimaProcesada DATE = (SELECT MAX(Fecha) FROM dbo.FechaProcesada);
IF @UltimaProcesada IS NOT NULL SET @Fecha = DATEADD(DAY, 1, @UltimaProcesada);

CREATE TABLE #MovDia(
    Orden INT IDENTITY(1,1),
    Tipo VARCHAR(64),
    NumeroCuenta VARCHAR(64),
    Monto DECIMAL(12,2),
    Descripcion NVARCHAR(256)
);
CREATE TABLE #Cierres(
    Orden INT IDENTITY(1,1),
    IdEstadoCuenta INT
);

DECLARE @FechaTexto VARCHAR(10);
DECLARE @i INT;
DECLARE @n INT;
DECLARE @Tipo VARCHAR(64);
DECLARE @NumeroCuenta VARCHAR(64);
DECLARE @Monto DECIMAL(12,2);
DECLARE @Descripcion NVARCHAR(256);
DECLARE @IdEstado INT;

WHILE @Fecha <= @FechaFin
BEGIN
    SET @FechaTexto = CONVERT(VARCHAR(10), @Fecha, 23);

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Personas, cuentas, beneficiarios, usuarios y permisos del día
        EXEC dbo.SpCargarEntidadesDia @xml, @Fecha;

        -- 2. Movimientos del día, en el mismo orden en que vienen en el XML
        TRUNCATE TABLE #MovDia;
        INSERT INTO #MovDia (Tipo, NumeroCuenta, Monto, Descripcion)
        SELECT movimiento.value('@Tipo', 'VARCHAR(64)'),
               movimiento.value('@CodigoCuenta', 'VARCHAR(64)'),
               movimiento.value('@Monto', 'DECIMAL(12,2)'),
               movimiento.value('@Descripcion', 'NVARCHAR(256)')
        FROM @xml.nodes('/Operaciones/FechaOperacion[@Fecha=sql:variable("@FechaTexto")]/Movimientos') AS tablaMovimientos(movimiento)
        ORDER BY movimiento.value('count(./preceding-sibling::Movimientos)', 'INT');

        SELECT @i = 1, @n = COUNT(*) FROM #MovDia;
        WHILE @i <= @n
        BEGIN
            SELECT @Tipo = Tipo, @NumeroCuenta = NumeroCuenta, @Monto = Monto, @Descripcion = Descripcion
            FROM #MovDia WHERE Orden = @i;

            EXEC dbo.SpAplicarMovimiento @NumeroCuenta, @Tipo, @Fecha, @Monto, @Descripcion;
            SET @i = @i + 1;
        END

        -- 3. Cierre de los estados que vencen hoy, el siguiente se abre dentro del cierre
        TRUNCATE TABLE #Cierres;
        INSERT INTO #Cierres (IdEstadoCuenta)
        SELECT estado.IdEstadoCuenta
        FROM dbo.Estado_de_Cuenta estado
        WHERE estado.EstaAbierto = 1 AND estado.fechafin = @Fecha
        ORDER BY estado.IdEstadoCuenta;

        SELECT @i = 1, @n = COUNT(*) FROM #Cierres;
        WHILE @i <= @n
        BEGIN
            SELECT @IdEstado = IdEstadoCuenta FROM #Cierres WHERE Orden = @i;
            EXEC dbo.SpCerrarEstadoCuenta @IdEstado;
            SET @i = @i + 1;
        END

        -- 4. Marca la fecha como procesada
        INSERT INTO dbo.FechaProcesada (Fecha) VALUES (@Fecha);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'Fallo el procesamiento de la fecha ' + @FechaTexto;
        THROW;
    END CATCH

    SET @Fecha = DATEADD(DAY, 1, @Fecha);
END

DROP TABLE #MovDia;
DROP TABLE #Cierres;
GO