USE CuentaAhorro;
SET XACT_ABORT ON;

DECLARE @xml XML;
SELECT @xml = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\GitHub\TAREA-PROGRAMADA-2\pruebas\CatalogosTarea3.xml', SINGLE_BLOB) AS temp;

BEGIN TRAN;
INSERT INTO dbo.Tipos_Doc (Id, Nombre)
SELECT
    tipoDoc.value('@Id', 'INT'),
    tipoDoc.value('@Nombre', 'VARCHAR(32)')
FROM @xml.nodes('/Catalogos/Tipo_Doc/TipoDocuIdentidad') AS tablaTiposDoc(tipoDoc);

INSERT INTO dbo.Tipos_Moneda (Id, Nombre, Simbolo)
SELECT
    moneda.value('@Id', 'INT'),
    moneda.value('@Nombre', 'VARCHAR(64)'),
    moneda.value('@Simbolo', 'NVARCHAR(16)')
FROM @xml.nodes('/Catalogos/Tipo_Moneda/TipoMoneda') AS tablaMonedas(moneda);

INSERT INTO dbo.Parentezco (Id, Nombre)
SELECT
    parentezco.value('@Id', 'INT'),
    parentezco.value('@Nombre', 'VARCHAR(32)')
FROM @xml.nodes('/Catalogos/Parentezcos/Parentezco') AS tablaParentezcos(parentezco);

INSERT INTO dbo.Tipo_Cuenta_Ahorros (Id, Nombre, IdTipoMoneda, SaldoMinimo, MultaSaldoMin, CargoMensual,
    NumRetirosHumano, NumRetirosAutomatico, ComisionHumano, ComisionAutomatico,
    MontoMaxSinpeDiario, ComisionSinpe, TasaInteresAnual)
SELECT
    tipoCuenta.value('@Id', 'INT'),
    tipoCuenta.value('@Nombre', 'VARCHAR(64)'),
    tipoCuenta.value('@IdTipoMoneda', 'INT'),
    tipoCuenta.value('@SaldoMinimo', 'DECIMAL(12,2)'),
    tipoCuenta.value('@MultaSaldoMin', 'DECIMAL(12,2)'),
    tipoCuenta.value('@CargoMensual', 'DECIMAL(12,2)'),
    tipoCuenta.value('@NumRetirosHumano', 'INT'),
    tipoCuenta.value('@NumRetirosAutomatico', 'INT'),
    tipoCuenta.value('@ComisionHumano', 'DECIMAL(12,2)'),
    tipoCuenta.value('@ComisionAutomatico', 'DECIMAL(12,2)'),
    tipoCuenta.value('@MontoMaxSinpeDiario', 'DECIMAL(12,2)'),
    tipoCuenta.value('@ComisionSinpe', 'DECIMAL(12,2)'),
    tipoCuenta.value('@TasaInteresAnual', 'DECIMAL(5,2)')
FROM @xml.nodes('/Catalogos/Tipo_Cuenta_Ahorros/TipoCuentaAhorro') AS tablaTiposCuenta(tipoCuenta);

INSERT INTO dbo.Tipos_Movimiento (Id, Nombre, Accion, FlagGeneraComprobante)
SELECT
    tipoMovimiento.value('@Id', 'INT'),
    tipoMovimiento.value('@Nombre', 'VARCHAR(64)'),
    tipoMovimiento.value('@Accion', 'VARCHAR(8)'),
    tipoMovimiento.value('@flagGeneraComprobante', 'BIT')
FROM @xml.nodes('/Catalogos/Tipos_Movimiento/TipoMovimiento') AS tablaTiposMovimiento(tipoMovimiento);

INSERT INTO dbo.TipoOpreacionesBitacora (Id, Nombre)
SELECT
    operacion.value('@Id', 'INT'),
    operacion.value('@Nombre', 'VARCHAR(64)')
FROM @xml.nodes('/Catalogos/TipoOperacionesBitacora/TipoOperacion') AS tablaOperaciones(operacion);

COMMIT;
GO