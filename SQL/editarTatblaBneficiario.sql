USE CuentaAhorro;

ALTER TABLE dbo.Beneficiario ADD
    banderaActiva BIT NOT NULL CONSTRAINT DF_Beneficiario_banderaActiva DEFAULT 1,
    FechaDesactivacion DATE NULL;
GO

CREATE UNIQUE INDEX UX_Beneficiario_Activo
ON dbo.Beneficiario (NumeroCuenta, ValorDocumentoIdentidadBeneficiario)
WHERE banderaActiva = 1;
GO
/*
agregarmos la fecha de desactivacion y la bandera activa para poder desactivar beneficiarios sin 
perder la informacion de los mismos, ademas de agregar un indice unico para que     
no se repitan beneficiarios activos en una misma cuenta.
*/