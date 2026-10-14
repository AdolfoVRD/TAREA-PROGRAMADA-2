USE CuentaAhorro;
DROP TABLE IF EXISTS dbo.Usuarios_Ver;
DROP TABLE IF EXISTS dbo.Estado_de_Cuenta;
DROP TABLE IF EXISTS dbo.Beneficiario;
DROP TABLE IF EXISTS dbo.Cuenta;
DROP TABLE IF EXISTS dbo.Usuario;
DROP TABLE IF EXISTS dbo.Persona;
CREATE TABLE dbo.Persona(
    IdPersona INT IDENTITY(1,1) PRIMARY KEY,
    TipoDocuIdentidad INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,
    ValorDocumentoIdentidad VARCHAR(32) NOT NULL UNIQUE,
    FechaNacimiento DATE NOT NULL,
    Email VARCHAR(128) NOT NULL,
    telefono1 VARCHAR(32) NOT NULL,
    telefono2 VARCHAR(32) NOT NULL,
    FOREIGN KEY (TipoDocuIdentidad) REFERENCES dbo.Tipos_Doc(Id)
);

CREATE TABLE dbo.Cuenta(
    IdCuenta INT IDENTITY(1,1) PRIMARY KEY,
    IdPersona INT NOT NULL,
    TipoCuentaId INT NOT NULL,
    NumeroCuenta VARCHAR(64) NOT NULL UNIQUE,
    FechaCreacion DATE NOT NULL,
    Saldo DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (IdPersona) REFERENCES dbo.Persona(IdPersona),
    FOREIGN KEY (TipoCuentaId) REFERENCES dbo.Tipo_Cuenta_Ahorros(Id)
);

CREATE TABLE dbo.Beneficiario(
    IdBeneficiario INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(64) NOT NULL,
    ValorDocumentoIdentidadBeneficiario VARCHAR(32) NOT NULL,
    IdParentezco INT NOT NULL,
    Porcentaje DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta),
    FOREIGN KEY (ValorDocumentoIdentidadBeneficiario) REFERENCES dbo.Persona(ValorDocumentoIdentidad),
    FOREIGN KEY (IdParentezco) REFERENCES dbo.Parentezco(Id),
    UNIQUE (NumeroCuenta, ValorDocumentoIdentidadBeneficiario)
);

CREATE TABLE dbo.Estado_de_Cuenta(
    IdEstadoCuenta INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(64) NOT NULL,
    fechaInicio DATE NOT NULL,
    fechafin DATE NOT NULL,
    saldoinicial DECIMAL(12,2) NOT NULL,
    saldoMinimo DECIMAL(12,2) NOT NULL,
    saldo_final DECIMAL(12,2) NOT NULL,
    interesesAcumulados DECIMAL(12,2) NOT NULL,
    cantRetiros INT NOT NULL,
    cantDepositos INT NOT NULL,
    cantSinpeEntrantes INT NOT NULL,
    cantSinpeSalientes INT NOT NULL,
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta),
    UNIQUE (NumeroCuenta, fechaInicio)
);

CREATE TABLE dbo.Usuario(
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    User_ VARCHAR(32) NOT NULL UNIQUE,
    Pass VARCHAR(32) NOT NULL,
    EsAdministrador BIT NOT NULL,
    ValorDocId VARCHAR(32) NOT NULL UNIQUE,
    FOREIGN KEY (ValorDocId) REFERENCES dbo.Persona(ValorDocumentoIdentidad)
);

CREATE TABLE dbo.Usuarios_Ver(
    IdUsuarios_Ver INT IDENTITY(1,1) PRIMARY KEY,
    User_ VARCHAR(32) NOT NULL,
    NumeroCuenta VARCHAR(64) NOT NULL,
    FOREIGN KEY (User_) REFERENCES dbo.Usuario(User_),
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta),
    UNIQUE (User_, NumeroCuenta)
);

CREATE TABLE dbo.Bitacora(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NOT NULL,
    IdOperacion INT NOT NULL,
    Fecha DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuario (IdUsuario),
    FOREIGN KEY (IdOperacion) REFERENCES dbo.TipoOpreacionesBitacora (Id)
);