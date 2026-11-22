
CREATE OR ALTER TRIGGER dbo.TrAbrirPrimerEstadoCuenta
ON dbo.Cuenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Estado_de_Cuenta (NumeroCuenta, fechaInicio, fechafin, saldoinicial, saldoMinimo, saldo_final)
    SELECT cuentaNueva.NumeroCuenta,
           cuentaNueva.FechaCreacion,
           DATEADD(MONTH, 1, cuentaNueva.FechaCreacion),
           cuentaNueva.Saldo,
           cuentaNueva.Saldo,
           cuentaNueva.Saldo
    FROM inserted cuentaNueva;
END
GO
