USE CuentaAhorro;
GO


CREATE OR ALTER PROCEDURE dbo.SpActualizarBitacora
-- Este procedimiento sse encarga de actualizar la bitacora, requiere de un usuario y el id del tipo de operacion
    @IdUsuario INT,
    @IdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE IdUsuario = @IdUsuario) RETURN;


    INSERT INTO dbo.Bitacora (IdUsuario, IdOperacion)
    VALUES (@IdUsuario, @IdOperacion);
END
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarTipoOperacion
-- Este procedimiento recibe el id de un tipo de operacion y muestra el nombre de dicha operacion
    @IdOperacion INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Nombre
    FROM dbo.TipoOpreacionesBitacora
    WHERE Id = @IdOperacion;

END
GO
CREATE OR ALTER PROCEDURE dbo.SpConsultarBitacora
    @IdUsuario Int
AS
BEGIN
-- Este procedimiento se encarga de consultar la bitacora utilizando el id del usuario
    SET NOCOUNT ON;
    SELECT
        Id,
        IdUsuario,
        IdOperacion,
        Fecha
    FROM dbo.Bitacora
    WHERE IdUsuario = @IdUsuario
END
GO
