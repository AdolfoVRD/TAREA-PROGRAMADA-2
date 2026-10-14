USE CuentaAhorro;
GO


CREATE OR ALTER PROCEDURE dbo.SpActualizarBitacora
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
    SELECT
        Id,
        IdUsuario,
        IdOperacion,
        Fecha
    FROM dbo.Bitacora
    WHERE IdUsuario = @IdUsuario
END
GO
