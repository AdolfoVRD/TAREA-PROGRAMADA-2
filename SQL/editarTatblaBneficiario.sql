USE CuentaAhorro;

ALTER TABLE dbo.Beneficiario ADD
    flagActivo BIT NOT NULL CONSTRAINT DF_Beneficiario_flagActivo DEFAULT 1,
    FechaDesactivacion DATE NULL;
GO
USE CuentaAhorro;

DECLARE @nombre NVARCHAR(128);
SELECT @nombre = name FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('dbo.Beneficiario') AND type = 'UQ';
IF @nombre IS NOT NULL
    EXEC('ALTER TABLE dbo.Beneficiario DROP CONSTRAINT ' + @nombre);
GO

CREATE UNIQUE INDEX UX_Beneficiario_Activo
ON dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario)
WHERE flagActivo = 1;
GO
