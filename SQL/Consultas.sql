USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarBeneficiarios
    @NumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT beneficiario.IdBeneficiario,
           beneficiario.ValorDocumentoIdentidadBeneficiario,
           persona.Nombre,
           beneficiario.IdParentezco,
           beneficiario.Porcentaje
    FROM dbo.Beneficiario beneficiario
    JOIN dbo.Persona persona
        ON persona.ValorDocumentoIdentidad = beneficiario.ValorDocumentoIdentidadBeneficiario
    WHERE beneficiario.NumeroCuenta = @NumeroCuenta
      AND beneficiario.flagActivo = 1
    ORDER BY beneficiario.IdBeneficiario;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpInsertarBeneficiario
    @NumeroCuenta VARCHAR(64),
    @ValorDoc VARCHAR(32),
    @IdParentezco INT,
    @Porcentaje DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Porcentaje IS NULL OR @Porcentaje <= 0 OR @Porcentaje > 100 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cuenta WHERE NumeroCuenta = @NumeroCuenta) RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Persona WHERE ValorDocumentoIdentidad = @ValorDoc) RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Parentezco WHERE Id = @IdParentezco) RETURN;

    IF (SELECT COUNT(*) FROM dbo.Beneficiario
        WHERE NumeroCuenta = @NumeroCuenta AND flagActivo = 1) >= 3 RETURN;

    IF EXISTS (SELECT 1 FROM dbo.Beneficiario
               WHERE NumeroCuenta = @NumeroCuenta
                 AND ValorDocumentoIdentidadBeneficiario = @ValorDoc
                 AND flagActivo = 1) RETURN;

    INSERT INTO dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario, IdParentezco, Porcentaje)
    VALUES (@NumeroCuenta, @ValorDoc, @IdParentezco, @Porcentaje);
END
GO

CREATE OR ALTER PROCEDURE dbo.SpActualizarBeneficiario
    @NumeroCuenta VARCHAR(64),
    @IdBeneficiario INT,
    @Nombre VARCHAR(64),
    @IdParentezco INT,
    @Porcentaje DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @Nombre = LTRIM(RTRIM(ISNULL(@Nombre, '')));
    IF @Nombre = '' RETURN;
    IF @Porcentaje IS NULL OR @Porcentaje <= 0 OR @Porcentaje > 100 RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Parentezco WHERE Id = @IdParentezco) RETURN;
    IF NOT EXISTS (SELECT 1 FROM dbo.Beneficiario
                   WHERE IdBeneficiario = @IdBeneficiario
                     AND NumeroCuenta = @NumeroCuenta
                     AND flagActivo = 1) RETURN;

    BEGIN TRAN;

    UPDATE dbo.Beneficiario
    SET IdParentezco = @IdParentezco,
        Porcentaje = @Porcentaje
    WHERE IdBeneficiario = @IdBeneficiario;

    UPDATE persona
    SET persona.Nombre = @Nombre
    FROM dbo.Persona persona
    JOIN dbo.Beneficiario beneficiario
        ON beneficiario.ValorDocumentoIdentidadBeneficiario = persona.ValorDocumentoIdentidad
    WHERE beneficiario.IdBeneficiario = @IdBeneficiario;

    COMMIT;
END
GO

CREATE OR ALTER PROCEDURE dbo.SpEliminarBeneficiario
    @NumeroCuenta VARCHAR(64),
    @IdBeneficiario INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Beneficiario
    SET flagActivo = 0,
        FechaDesactivacion = CAST(GETDATE() AS DATE)
    WHERE IdBeneficiario = @IdBeneficiario
      AND NumeroCuenta = @NumeroCuenta
      AND flagActivo = 1;
END
GO