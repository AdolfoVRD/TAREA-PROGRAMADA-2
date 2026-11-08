CREATE DATABASE CuentaAhorro;
USE CuentaAhorro;

DROP TABLE IF EXISTS dbo.Tipos_Doc;
DROP TABLE IF EXISTS dbo.Tipos_Moneda;  
DROP TABLE IF EXISTS dbo.Parentezco;
DROP TABLE IF EXISTS dbo.Tipo_Cuenta_Ahorros;
DROP TABLE IF EXISTS dbo.TipoOpreacionesBitacora;

CREATE TABLE dbo.Tipos_Doc(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL
);
CREATE TABLE dbo.Tipos_Moneda(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    Simbolo VARCHAR(16) NOT NULL
);
CREATE TABLE dbo.Parentezco(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL
);

CREATE TABLE dbo.Tipo_Cuenta_Ahorros(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL,
    IdTipoMoneda INT NOT NULL,
    FOREIGN KEY (IdTipoMoneda) REFERENCES dbo.Tipos_Moneda(Id),
    SaldoMinimo MONEY NOT NULL, 
    MultaSaldMin MONEY NOT NULL,
    CargoAnual MONEY NOT NULL,
    NumRetirosHumanos INT NOT NULL,
    NumRetirosAutomatico INT NOT NULL,
    comisionHumano MONEY NOT NULL,
    comisionAutomatico MONEY NOT NULL,
    intereses INT NOT NULL
);

CREATE TABLE dbo.TipoOpreacionesBitacora(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(64) NOT NULL
);


