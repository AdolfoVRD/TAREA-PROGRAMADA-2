USE CuentaAhorro;
SELECT @@SERVERNAME AS Servidor, @@VERSION AS Version, SUSER_SNAME() AS Usuario, DB_NAME() AS Base;