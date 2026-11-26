USE CuentaAhorro;
GO


CREATE OR ALTER PROCEDURE dbo.SpActualizarBitacora
-- Este procedimiento sse encarga de actualizar la bitacora, requiere de un usuario y el id del tipo de operacion
    @inIdUsuario INT,
    @inIdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE IdUsuario = @inIdUsuario) RETURN;


        INSERT INTO dbo.Bitacora (IdUsuario, IdOperacion)
        VALUES (@inIdUsuario, @inIdOperacion);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarTipoOperacion
-- Este procedimiento recibe el id de un tipo de operacion y muestra el nombre de dicha operacion
    @inIdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
            Nombre
        FROM dbo.TipoOpreacionesBitacora
        WHERE Id = @inIdOperacion;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarBitacora
    @inIdUsuario Int
AS
BEGIN
-- Este procedimiento se encarga de consultar la bitacora utilizando el id del usuario
    SET NOCOUNT ON;
    BEGIN TRY
        SELECT
            Id,
            IdUsuario,
            IdOperacion,
            Fecha
        FROM dbo.Bitacora
        WHERE IdUsuario = @inIdUsuario
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
