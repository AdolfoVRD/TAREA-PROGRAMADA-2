USE CuentaAhorro;
GO

CREATE OR ALTER PROCEDURE dbo.SpConsultarBeneficiarios
    @inNumeroCuenta VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT beneficiario.IdBeneficiario,
               beneficiario.ValorDocumentoIdentidadBeneficiario,
               persona.Nombre,
               beneficiario.IdParentezco,
               beneficiario.Porcentaje
        FROM dbo.Beneficiario beneficiario
        JOIN dbo.Persona persona
            ON persona.ValorDocumentoIdentidad = beneficiario.ValorDocumentoIdentidadBeneficiario
        WHERE beneficiario.NumeroCuenta = @inNumeroCuenta
          AND beneficiario.banderaActiva = 1
        ORDER BY beneficiario.IdBeneficiario;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
/*
Utilizamos el join con la tabla persona para poder obtener el nombre del beneficiario, 
ademas de filtrar por la bandera activa para que solo se muestren los beneficiarios activos.
*/
CREATE OR ALTER PROCEDURE dbo.SpInsertarBeneficiario
    @inNumeroCuenta VARCHAR(64),
    @inValorDoc VARCHAR(32),
    @inIdParentezco INT,
    @inPorcentaje DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @inPorcentaje IS NULL OR @inPorcentaje <= 0 OR @inPorcentaje > 100 RETURN;
        IF NOT EXISTS (SELECT 1 FROM dbo.Cuenta WHERE NumeroCuenta = @inNumeroCuenta) RETURN;
        IF NOT EXISTS (SELECT 1 FROM dbo.Persona WHERE ValorDocumentoIdentidad = @inValorDoc) RETURN;
        IF NOT EXISTS (SELECT 1 FROM dbo.Parentezco WHERE Id = @inIdParentezco) RETURN;

        IF (SELECT COUNT(*) FROM dbo.Beneficiario
            WHERE NumeroCuenta = @inNumeroCuenta AND banderaActiva = 1) >= 3 RETURN;

        IF EXISTS (SELECT 1 FROM dbo.Beneficiario
                   WHERE NumeroCuenta = @inNumeroCuenta
                     AND ValorDocumentoIdentidadBeneficiario = @inValorDoc
                     AND banderaActiva = 1) RETURN;

        INSERT INTO dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario, IdParentezco, Porcentaje)
        VALUES (@inNumeroCuenta, @inValorDoc, @inIdParentezco, @inPorcentaje);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
/*
El quinto if verifica si hay activos y que no hayan mas de 3.
El sexto if verifica que no se repita un beneficiario activo en la misma cuenta.
*/
CREATE OR ALTER PROCEDURE dbo.SpActualizarBeneficiario
    @inNumeroCuenta VARCHAR(64),
    @inIdBeneficiario INT,
    @inNombre VARCHAR(64),
    @inIdParentezco INT,
    @inPorcentaje DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;--Si hay error que no proceda(evitar errores)--
    BEGIN TRY
        SET @inNombre = LTRIM(RTRIM(ISNULL(@inNombre, '')));--quitar espacios--
        IF @inNombre = '' RETURN;
        IF @inPorcentaje IS NULL OR @inPorcentaje <= 0 OR @inPorcentaje > 100 RETURN;
        IF NOT EXISTS (SELECT 1 FROM dbo.Parentezco WHERE Id = @inIdParentezco) RETURN;
        IF NOT EXISTS (SELECT 1 FROM dbo.Beneficiario
                       WHERE IdBeneficiario = @inIdBeneficiario
                         AND NumeroCuenta = @inNumeroCuenta
                         AND banderaActiva = 1) RETURN;

        BEGIN TRAN;

        UPDATE dbo.Beneficiario
        SET IdParentezco = @inIdParentezco,
            Porcentaje = @inPorcentaje
        WHERE IdBeneficiario = @inIdBeneficiario;

        UPDATE persona
        SET persona.Nombre = @inNombre
        FROM dbo.Persona persona
        JOIN dbo.Beneficiario beneficiario
            ON beneficiario.ValorDocumentoIdentidadBeneficiario = persona.ValorDocumentoIdentidad
        WHERE beneficiario.IdBeneficiario = @inIdBeneficiario;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.SpEliminarBeneficiario
    @inNumeroCuenta VARCHAR(64),
    @inIdBeneficiario INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE dbo.Beneficiario
        SET banderaActiva = 0,
            FechaDesactivacion = CAST(GETDATE() AS DATE)--para quitar hora--
        WHERE IdBeneficiario = @inIdBeneficiario
          AND NumeroCuenta = @inNumeroCuenta
          AND banderaActiva = 1;--para no eliminar beneficiarios que ya fueron eliminados--
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO