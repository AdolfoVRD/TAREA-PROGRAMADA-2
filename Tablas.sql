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
    Nombre VARCHAR(32) NOT NULL,
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
    Nombre VARCHAR(32) NOT NULL
);

INSERT INTO dbo.Tipos_Doc (Id, Nombre) VALUES
(1, 'Cedula Nacional'),
(2, 'Celula de Residente'),
(3, 'Carnet de Pasaporte'),
(4, 'Cedula Juridica'),
(5, 'Permiso de Trabajo'),
(6, 'Cedula Extranjera');

INSERT INTO dbo.Tipos_Moneda (Id, Nombre, Simbolo) VALUES
(1, 'Colones', '₡'),
(2, 'Dolares', '$'),
(3, 'Euros', '€');

INSERT INTO dbo.Parentezco (Id, Nombre) VALUES
(1, 'Padre'),
(2, 'Madre'),
(3, 'Hijo'),
(4, 'Hija'),
(5, 'Hermano'),
(6, 'Hermana'),
(7, 'Amigo'),
(8, 'Amiga');

INSERT INTO dbo.Tipo_Cuenta_Ahorros (Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldMin, CargoAnual, NumRetirosHumanos, NumRetirosAutomatico, comisionHumano, comisionAutomatico, intereses) VALUES
(1, 'Proletario', 1, 25000.00, 3000.00, 5000.00, 5, 8, 300.00, 300.00, 10),
(2, 'Profesional', 1, 50000.00, 3000.00, 15000.00, 5, 8, 500.00, 500.00, 15),
(3, 'Exclusivo', 1, 100000.00, 3000.00, 30000.00, 5, 8, 1000.00, 1000.00, 20);


INSERT INTO dbo.TipoOpreacionesBitacora (Id, Nombre) VALUES
(1, 'Login'),
(2, 'Logout'),
(3, 'Agregar Beneficiario'),
(4, 'Actualizar Beneficiario'),
(5, 'Eliminar Beneficiario'),
(6, 'Eliminar Cuenta Ahorro'),
(7, 'Actualizar Porcentaje de Beneficiario'),
(8, 'Consultar estado de Cuenta');


