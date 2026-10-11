USE CuentaAhorro;
SET XACT_ABORT ON;
BEGIN TRAN;

DELETE FROM dbo.Usuarios_Ver;
DELETE FROM dbo.Estado_de_Cuenta;
DELETE FROM dbo.Beneficiario;
DELETE FROM dbo.Usuario;
DELETE FROM dbo.Cuenta;
DELETE FROM dbo.Persona;

DBCC CHECKIDENT ('dbo.Usuarios_Ver', RESEED, 0);
DBCC CHECKIDENT ('dbo.Estado_de_Cuenta', RESEED, 0);
DBCC CHECKIDENT ('dbo.Beneficiario', RESEED, 0);
DBCC CHECKIDENT ('dbo.Usuario', RESEED, 0);
DBCC CHECKIDENT ('dbo.Cuenta', RESEED, 0);
DBCC CHECKIDENT ('dbo.Persona', RESEED, 0);

COMMIT;