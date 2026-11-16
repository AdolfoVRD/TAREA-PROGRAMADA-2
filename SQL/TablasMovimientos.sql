USE CuentaAhorro;

CREATE TABLE dbo.Movimientos(
    Id INT PRIMARY KEY,
    Tipo varchar(64) NOT NULL,
    CodigoCuenta VARCHAR(64) NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    Descripcion varchar(256) NOT NULL,
    FOREIGN KEY (CodigoCuenta) REFERENCES dbo.Cuenta(NumeroCuenta)
);