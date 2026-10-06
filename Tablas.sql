CREATE DATABASE CuentaAhorro;
USE CuentaAhorro;
CREATE TABLE dbo.Tipos_Doc(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL,
);
CREATE TABLE dbo.Tipos_Moneda(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL,
    Simbolo TEXT NOT NULL
);
CREATE TABLE dbo.Parentezco(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL
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

