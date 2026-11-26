USE CuentaAhorro;
SET XACT_ABORT ON;
SET NOCOUNT ON;


--CREATE MASTER KEY
--ENCRYPTION BY PASSWORD = 'Adminbd3tareabd3!';


--CREATE DATABASE SCOPED CREDENTIAL CredencialBlob
--WITH
--    IDENTITY = 'SHARED ACCESS SIGNATURE',
--    SECRET = 'sp=racwdli&st=2026-11-19T06:21:30Z&se=2026-11-29T14:36:30Z&spr=https&sv=2026-02-06&sr=c&sig=VxDV6h01lDaUNpBttx0R9IWpiUmkqJQcdp%2BkH7zhVu8%3D';


--CREATE EXTERNAL DATA SOURCE FuenteBlob
--WITH (
--    TYPE = BLOB_STORAGE,
--    LOCATION = 'https://tareabd3.blob.core.windows.net/tareabd3',
--    CREDENTIAL = CredencialBlob
--);

SELECT
    name,
    type_desc,
    location
FROM sys.external_data_sources
WHERE name = 'FuenteBlob';

DECLARE @xml XML;
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(
    BULK 'OperacionesTarea3.xml',
    DATA_SOURCE = 'FuenteBlob',
    SINGLE_BLOB
) AS Archivo;

SELECT @xml AS XmlData;

-- Rango de fechas que trae el XML
DECLARE @Fecha DATE;
DECLARE @FechaFin DATE;
SELECT @Fecha = MIN(dia.value('@Fecha', 'DATE')),
       @FechaFin = MAX(dia.value('@Fecha', 'DATE'))
FROM @xml.nodes('/Operaciones/FechaOperacion') AS tablaDias(dia);

-- Se crea una tabla temporal para almacenar los movimientos del día
CREATE TABLE #MovimientosDia
(
    IdTemporal INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    NumeroCuenta VARCHAR(64) NOT NULL,
    NombreTipo VARCHAR(64) NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    Descripcion NVARCHAR(256)
);

-- Comienza el proceso desde la fecha siguiente
WHILE @Fecha <= @FechaFin
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        --- Se crean Personas, cuentas, beneficiarios, usuarios y permisos del día
        EXEC dbo.SpCargarEntidadesDia
            @xml, @Fecha;

        -- Se procesan los movimientos del día
        -- Primero se insertan en la tabla temporal #MovimientosDia desde el xml
        TRUNCATE TABLE #MovimientosDia;
       INSERT INTO #MovimientosDia
        (
            Fecha,
            NumeroCuenta,
            NombreTipo,
            Monto,
            Descripcion
        )
        SELECT
            F.N.value('@Fecha', 'DATE'),
            M.N.value('@CodigoCuenta', 'VARCHAR(64)'),
            LTRIM(RTRIM(M.N.value('@Tipo', 'VARCHAR(64)'))),
            M.N.value('@Monto', 'DECIMAL(12,2)'),
            M.N.value('@Descripcion', 'NVARCHAR(256)')
        FROM @xml.nodes('/Operaciones/FechaOperacion') AS F(N)
        CROSS APPLY F.N.nodes('Movimientos') AS M(N)
        -- Solo los movimientos del día que se está simulando
        WHERE F.N.value('@Fecha', 'DATE') = @Fecha;

        DECLARE @Posicion INT = 1;
        DECLARE @Cantidad INT;
        DECLARE @NumeroCuenta VARCHAR(64);
        DECLARE @NombreTipo VARCHAR(64);
        DECLARE @Monto DECIMAL(12,2);
        DECLARE @Descripcion NVARCHAR(256);

        -- Se establece el limite para el while
        SELECT @Cantidad = COUNT(*)
        FROM #MovimientosDia;

        -- Se procesan los movimientos del día en orden
        WHILE @Posicion <= @Cantidad
            BEGIN

                SELECT
                    @NumeroCuenta = NumeroCuenta,
                    @NombreTipo = NombreTipo,
                    @Monto = Monto,
                    @Descripcion = Descripcion
                FROM #MovimientosDia
                WHERE IdTemporal = @Posicion;

                EXEC dbo.SpAplicarMovimiento
                    @NumeroCuenta = @NumeroCuenta,
                    @NombreTipo = @NombreTipo,
                    @Fecha = @Fecha,
                    @Monto = @Monto,
                    @Descripcion = @Descripcion;

                SET @Posicion = @Posicion + 1;

            END;

            --- Se cierran los estados de cuenta que tengan fecha de cierre igual a la fecha actual
            DECLARE @IdEstadoCuenta INT;

            WHILE EXISTS (
                SELECT 1
                FROM dbo.Estado_de_Cuenta
                WHERE FechaFin = @Fecha
                AND EstaAbierto = 1
            )
            BEGIN

                SELECT TOP 1
                    @IdEstadoCuenta = IdEstadoCuenta
                FROM dbo.Estado_de_Cuenta
                WHERE FechaFin = @Fecha
                AND EstaAbierto = 1
                ORDER BY IdEstadoCuenta;

                EXEC dbo.SpCerrarEstadoCuenta
                    @IdEstadoCuenta = @IdEstadoCuenta;

            END;
            COMMIT TRANSACTION;

            -- Pasar al siguiente día
            PRINT 'Se ha procesado el día: ' + CAST(@Fecha AS NVARCHAR(10));
            SET @Fecha = DATEADD(DAY, 1, @Fecha);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        PRINT 'Error en la fecha: ' + CAST(@Fecha AS NVARCHAR(10)) + ' - ' + ERROR_MESSAGE();
        -- Se detiene la simulación: seguir sin este día dejaría los saldos incorrectos
        BREAK;
    END CATCH
END;
DROP TABLE #MovimientosDia;
GO