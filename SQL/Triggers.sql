
CREATE OR ALTER TRIGGER dbo.TrCuentaInsert
ON dbo.Cuenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Estado_de_Cuenta
    (
        NumeroCuenta,
        fechaInicio,
        fechafin,
        saldoinicial,
        saldo_final,
        saldoMinimo,
        cantOpATM,
        cantOpHUmano,
        cantOpSinpe,
        EstaAbierto
    )
    SELECT
        i.NumeroCuenta,
        i.FechaCreacion,
        NULL,
        i.Saldo,
        i.Saldo,
        i.Saldo,
        0,
        0,
        0,
        1
    FROM inserted AS i;
END;
GO
