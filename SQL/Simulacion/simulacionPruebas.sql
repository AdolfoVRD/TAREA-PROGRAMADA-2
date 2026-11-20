USE CuentaAhorro;
SET XACT_ABORT ON;
SET NOCOUNT ON;


DROP TABLE IF EXISTS #MovDia;
DROP TABLE IF EXISTS #Cierres;

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Adminbd3tareabd3!';


CREATE DATABASE SCOPED CREDENTIAL CredencialBlob
WITH
    IDENTITY = 'SHARED ACCESS SIGNATURE',
    SECRET = 'sp=racwdli&st=2026-11-19T06:21:30Z&se=2026-11-29T14:36:30Z&spr=https&sv=2026-02-06&sr=c&sig=VxDV6h01lDaUNpBttx0R9IWpiUmkqJQcdp%2BkH7zhVu8%3D';


CREATE EXTERNAL DATA SOURCE FuenteBlob
WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = 'https://tareabd3.blob.core.windows.net/tareabd3',
    CREDENTIAL = CredencialBlob
);
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



-- Comienza el proceso desde la fecha siguiente
WHILE @Fecha <= @FechaFin
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC dbo.SpCargarEntidadesDia
            @xml, @Fecha;

        COMMIT TRANSACTION;

        -- Pasar al siguiente día
        SET @Fecha = DATEADD(DAY, 1, @Fecha);
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        RETURN 500050;
    END CATCH
END;

GO