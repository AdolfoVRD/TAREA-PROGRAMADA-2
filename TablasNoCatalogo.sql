CREATE TABLE dbo.Persona(
    IdPersona INT IDENTITY(1,1) PRIMARY KEY,
    TipoDocuIdentidad INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,
    ValorDocumentoIdentidad VARCHAR(32) NOT NULL,
    FechaNacimiento DATE NOT NULL,  
    Email VARCHAR(32) NOT NULL,
    telefono1 VARCHAR(32) NOT NULL,
    telefono2 VARCHAR(32) NOT NULL,
    FOREIGN KEY (TipoDocuIdentidad) REFERENCES dbo.Tipos_Doc(Id)
);
CREATE TABLE dbo.Cuenta(
    IdCuenta INT IDENTITY(1,1) PRIMARY KEY,
    TipoCuentaId INT NOT NULL,
    NumeroCuenta VARCHAR(64) NOT NULL,
    FechaCreacion DATE NOT NULL,
    Saldo DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (TipoCuentaId) REFERENCES dbo.Tipo_Cuenta_Ahorros(Id)
);
CREATE TABLE dbo.Beneficiario(
    IdBeneficiario INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(64) NOT NULL,
    ValorDocumentoIdentidadBeneficiario VARCHAR(64) NOT NULL,
    IdParentezco INT NOT NULL,
    Porcentaje DECIMAL(5,2) NOT NULL,
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta)
);
CREATE TABLE dbo.Estado_de_Cuenta(
    IdEstadoCuenta INT IDENTITY(1,1) PRIMARY KEY,
    NumeroCuenta VARCHAR(64) NOT NULL,
    fechaInicio DATE NOT NULL,
    fechafin DATE NOT NULL,
    saldoinicial DECIMAL(10,2) NOT NULL,
    saldoMinimo DECIMAL(10,2) NOT NULL,
    saldo_final DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta)
);
CREATE TABLE dbo.Usuario(
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    User_ VARCHAR(32) NOT NULL,
    Pass VARCHAR(32) NOT NULL,
    EsAdministrador VARCHAR(64) NOT NULL,
    ValorDocId VARCHAR(32) NOT NULL,
    FOREIGN KEY (ValorDocId) REFERENCES dbo.Persona(ValorDocumentoIdentidad)
);
CREATE TABLE dbo.Usuarios_Ver(
    IdUsuarios_Ver INT IDENTITY(1,1) PRIMARY KEY,
    User_ VARCHAR(32) NOT NULL,
    NumeroCuenta VARCHAR(64) NOT NULL,
    FOREIGN KEY (NumeroCuenta) REFERENCES dbo.Cuenta(NumeroCuenta),
    FOREIGN KEY (User_) REFERENCES dbo.Usuario(User_)
);
