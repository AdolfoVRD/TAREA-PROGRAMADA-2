CREATE DATABASE IF NOT EXISTS CuentaAhorro;
USE CuentaAhorro;
CREATE TABLE IF NOT EXISTS 'Tipo_Doc'(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL,
)
CREATE TABLE IF NOT EXISTS 'Tipo_Moneda'(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL,
    Simbolo TEXT NOT NULL
)
CREATE TABLE IF NOT EXISTS 'Parentezco'(
    Id INTEGER PRIMARY KEY,
    Nombre TEXT NOT NULL
)
INSERT INTO Tipo_Doc (Id, Nombre) VALUES
(1, 'Cedula Nacional'),
(2, 'Celula de Residente'),
(3, 'Carnet de Pasaporte'),
(4, 'Cedula Juridica'),
(5, 'Permiso de Trabajo'),
(6, 'Cedula Extranjera');

INSERT INTO Tipo_Moneda (Id, Nombre, Simbolo) VALUES
(1, 'Colones', '₡'),
(2, 'Dolares', '$'),
(3, 'Euros', '€');

INSERT INTO Parentezco (Id, Nombre) VALUES
(1, 'Padre'),
(2, 'Madre'),
(3, 'Hijo'),
(4, 'Hija'),
(5, 'Hermano'),
(6, 'Hermana'),
(7, 'Amigo'),
(8, 'Amiga');

