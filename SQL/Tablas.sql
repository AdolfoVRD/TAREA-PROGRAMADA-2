USE CuentaAhorro;
GO

CREATE TABLE dbo.Tipos_Doc(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL
);

CREATE TABLE dbo.Tipos_Moneda(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    Simbolo NVARCHAR(16) NOT NULL
);

CREATE TABLE dbo.Parentezco(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL
);

CREATE TABLE dbo.Tipo_Cuenta_Ahorros(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    IdTipoMoneda INT NOT NULL,
    SaldoMinimo DECIMAL(12,2) NOT NULL,
    MultaSaldoMin DECIMAL(12,2) NOT NULL,
    CargoMensual DECIMAL(12,2) NOT NULL,
    NumRetirosHumano INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    ComisionHumano DECIMAL(12,2) NOT NULL,
    ComisionAutomatico DECIMAL(12,2) NOT NULL,
    MontoMaxSinpeDiario DECIMAL(12,2) NOT NULL,
    ComisionSinpe DECIMAL(12,2) NOT NULL,
    TasaInteresAnual DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (IdTipoMoneda) REFERENCES dbo.Tipos_Moneda(Id)
);

CREATE TABLE dbo.Tipos_Movimiento(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    Accion VARCHAR(8) NOT NULL CHECK (Accion IN ('Credito', 'Debito')),
    FlagGeneraComprobante BIT NOT NULL
);

CREATE TABLE dbo.TipoOpreacionesBitacora(
    Id INT PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL
);
GO