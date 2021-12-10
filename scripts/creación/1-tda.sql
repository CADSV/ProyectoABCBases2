CREATE OR REPLACE TYPE TDA_MANTENIMIENTO AS OBJECT (
    fecha_prox_mant DATE,
    STATIC FUNCTION fechaProxMant(fecha_ult_mant DATE DEFAULT CURRENT_DATE, num_meses INTEGER DEFAULT 1) RETURN DATE
);

/

CREATE OR REPLACE TYPE BODY TDA_MANTENIMIENTO AS
    STATIC FUNCTION fechaProxMant(fecha_ult_mant DATE DEFAULT CURRENT_DATE, num_meses INTEGER DEFAULT 1) RETURN DATE
    IS
    BEGIN
        return ADD_MONTHS(fecha_ult_mant,num_meses);
    END;
END;

/



CREATE OR REPLACE TYPE DATOS AS OBJECT (
    dat_tipo_cedula VARCHAR2(1),
    dat_cedula NUMBER,
    dat_primer_nombre VARCHAR2(40),
    dat_segundo_nombre VARCHAR2(40),
    dat_primer_apellido VARCHAR2(40),
    dat_segundo_apellido VARCHAR2(40),
    dat_genero VARCHAR2(1),
    dat_fecha_nacimiento DATE,
    dat_email VARCHAR2(320),
    dat_vacunado NUMBER(1),

    STATIC FUNCTION existeCedula (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER) RETURN NUMBER,
    STATIC FUNCTION validarCedula (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER) RETURN NUMBER,
    STATIC FUNCTION validarNombres (dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2 DEFAULT NULL, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2 DEFAULT NULL) RETURN NUMBER,
    STATIC FUNCTION validarGenero (dat_genero VARCHAR2) RETURN NUMBER,
    STATIC FUNCTION existeEmail (dat_email VARCHAR2) RETURN NUMBER,
    STATIC FUNCTION validarEmail (dat_email VARCHAR2) RETURN NUMBER,
    STATIC FUNCTION validarVacunado (dat_vacunado NUMBER) RETURN NUMBER,
    STATIC FUNCTION validarFechaNacimiento (dat_fecha_nacimiento DATE) RETURN NUMBER,
    STATIC FUNCTION validarDatos (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER, dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2 DEFAULT NULL, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2 DEFAULT NULL, dat_genero VARCHAR2, dat_fecha_nacimiento DATE, dat_email VARCHAR2, dat_vacunado NUMBER) RETURN NUMBER,
    STATIC FUNCTION obtenerEdad (fecha_nacimiento DATE) RETURN NUMBER,
    STATIC FUNCTION obtenerEdad (cli_id NUMBER) RETURN NUMBER,
    CONSTRUCTOR FUNCTION DATOS (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER, dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2 DEFAULT NULL, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2 DEFAULT NULL, dat_genero VARCHAR2, dat_fecha_nacimiento DATE, dat_email VARCHAR2, dat_vacunado NUMBER) RETURN SELF AS RESULT

);

/

CREATE OR REPLACE TYPE BODY DATOS AS

    STATIC FUNCTION existeCedula (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER) RETURN NUMBER
    IS
        cedula NUMBER;
    BEGIN
        SELECT cl.cli_datos.dat_cedula 
        INTO cedula
        FROM CLIENTE cl
        WHERE cl.cli_datos.dat_tipo_cedula = dat_tipo_cedula AND cl.cli_datos.dat_cedula = dat_cedula;
        RETURN 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 0;
    END;


    STATIC FUNCTION validarCedula (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF (DATOS.existeCedula(dat_tipo_cedula, dat_cedula) = 1) THEN
            RAISE_APPLICATION_ERROR(-20002,'Error. La cedula indicada ya existe en el sistema');
            RETURN 0;
        ELSIF (dat_tipo_cedula != 'V' AND dat_tipo_cedula != 'E') THEN
            RAISE_APPLICATION_ERROR(-20003,'Error. Tipo de cedula invalido. Debe ser V o E');
            RETURN 0;
        ELSIF (dat_cedula >= 999999999 OR dat_cedula = 0) THEN
            RAISE_APPLICATION_ERROR(-20004,'Error. Numero de cedula invalido');
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    STATIC FUNCTION validarNombres (dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2 DEFAULT NULL, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2 DEFAULT NULL) RETURN NUMBER
    IS
    BEGIN
        IF (LENGTH(dat_primer_nombre) < 2 OR LENGTH(dat_primer_apellido) < 2) THEN
            RAISE_APPLICATION_ERROR(-20005,'Error. Nombre o apellido muy corto');
        END IF;
        IF (LENGTH(TRIM(TRANSLATE(dat_primer_nombre, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZáéíóúäëïöü', ' '))) IS NULL) THEN
            IF (LENGTH(TRIM(TRANSLATE(dat_primer_nombre, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZáéíóúäëïöü', ' '))) IS NULL) THEN
                IF (LENGTH(TRIM(TRANSLATE(dat_primer_nombre, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZáéíóúäëïöü', ' '))) IS NULL) THEN
                    IF (LENGTH(TRIM(TRANSLATE(dat_primer_nombre, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZáéíóúäëïöü', ' '))) IS NULL) THEN
                        RETURN 1;
                    END IF;
                END IF;
            END IF;
        END IF;
        RAISE_APPLICATION_ERROR(-20006,'Error. Los nombres y apellidos solo pueden contener letras');
        RETURN 0;
    END;
    
    STATIC FUNCTION validarGenero (dat_genero VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        IF (dat_genero != 'M' AND dat_genero != 'F') THEN
            RAISE_APPLICATION_ERROR(-20007,'Error. Genero invalido');
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;
    
    STATIC FUNCTION existeEmail (dat_email VARCHAR2) RETURN NUMBER
    IS
        email VARCHAR2(320);
    BEGIN
        SELECT cl.cli_datos.dat_email
        INTO email
        FROM CLIENTE cl
        WHERE cl.cli_datos.dat_email = dat_email;
        RETURN 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 0;
    END;
    
    STATIC FUNCTION validarEmail (dat_email VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        IF(existeEmail(dat_email) = 1) THEN
            RAISE_APPLICATION_ERROR(-20008,'Error. El email indicado ya existe en el sistema');
            RETURN 0;
        ELSIF(REGEXP_LIKE (dat_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{1,4}$') AND LENGTH(dat_email) >= 3) THEN
            RETURN 1;
        ELSE
            RAISE_APPLICATION_ERROR(-20009,'Error. Email invalido');
            RETURN 0;
        END IF;
    END;
    
    STATIC FUNCTION validarVacunado (dat_vacunado NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF(dat_vacunado >= 0 AND dat_vacunado <= 1) THEN
            RETURN 1;
        ELSE
            RAISE_APPLICATION_ERROR(-20010,'Error. Informacion de vacunacion invalida');
            RETURN 0;
        END IF;
    END;
    
    STATIC FUNCTION validarFechaNacimiento (dat_fecha_nacimiento DATE) RETURN NUMBER
    IS
    BEGIN
        IF((dat_fecha_nacimiento > SYSDATE) OR (floor(months_between(SYSDATE, dat_fecha_nacimiento) /12) >= 130)) THEN
            RAISE_APPLICATION_ERROR(-20011,'Error. Fecha de nacimiento invalida');
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;
    
    STATIC FUNCTION validarDatos (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER, dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2, dat_genero VARCHAR2, dat_fecha_nacimiento DATE, dat_email VARCHAR2, dat_vacunado NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF (DATOS.validarCedula(dat_tipo_cedula, dat_cedula) = 0) THEN
            RETURN 0;
        ELSIF (DATOS.validarNombres(dat_primer_nombre, dat_segundo_nombre, dat_primer_apellido, dat_segundo_apellido) = 0) THEN
            RETURN 0;
        ELSIF (DATOS.validarGenero(dat_genero) = 0) THEN
            RETURN 0;
        ELSIF (DATOS.validarEmail(dat_email) = 0) THEN
            RETURN 0;
        ELSIF (DATOS.validarVacunado(dat_vacunado) = 0) THEN
            RETURN 0;
        ELSIF (DATOS.validarFechaNacimiento(dat_fecha_nacimiento) = 0) THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;

    STATIC FUNCTION obtenerEdad (fecha_nacimiento DATE) RETURN NUMBER
    IS
    BEGIN
        RETURN floor(months_between(SYSDATE, fecha_nacimiento) /12);
    END;
    
    STATIC FUNCTION obtenerEdad (cli_id NUMBER) RETURN NUMBER
    IS
        fecha_nacimiento DATE;
    BEGIN
        SELECT cl.cli_datos.dat_fecha_nacimiento 
        INTO fecha_nacimiento
        FROM CLIENTE cl
        WHERE cl.cli_id = 1;
        RETURN floor(months_between(SYSDATE, fecha_nacimiento) /12);
    END;

    CONSTRUCTOR FUNCTION DATOS (dat_tipo_cedula VARCHAR2, dat_cedula NUMBER, dat_primer_nombre VARCHAR2, dat_segundo_nombre VARCHAR2 DEFAULT NULL, dat_primer_apellido VARCHAR2, dat_segundo_apellido VARCHAR2 DEFAULT NULL, dat_genero VARCHAR2, dat_fecha_nacimiento DATE, dat_email VARCHAR2, dat_vacunado NUMBER) RETURN SELF AS RESULT
    IS
    BEGIN
        IF (DATOS.validarDatos(dat_tipo_cedula, dat_cedula, dat_primer_nombre, dat_segundo_nombre, dat_primer_apellido, dat_segundo_apellido, dat_genero, dat_fecha_nacimiento, dat_email, dat_vacunado) = 0) THEN
            RAISE_APPLICATION_ERROR(-20012,'Error al crear cliente');
        ELSE
            SELF.dat_tipo_cedula := dat_tipo_cedula;
            SELF.dat_cedula := dat_cedula;
            SELF.dat_primer_nombre := INITCAP(dat_primer_nombre);
            SELF.dat_segundo_nombre := INITCAP(dat_segundo_nombre);
            SELF.dat_primer_apellido := INITCAP(dat_primer_apellido);
            SELF.dat_segundo_apellido := INITCAP(dat_segundo_apellido);
            SELF.dat_genero := dat_genero;
            SELF.dat_fecha_nacimiento := dat_fecha_nacimiento;
            SELF.dat_email := dat_email;
            SELF.dat_vacunado := dat_vacunado;
            RETURN;
        END IF;
    END;
END;

/

CREATE OR REPLACE TYPE FECHA AS OBJECT(
    fecha_inicio DATE,
    fecha_fin DATE,
    cantidad_dias NUMBER,
    STATIC FUNCTION validarFechas ( fecha_inicio DATE, fecha_fin DATE ) RETURN NUMBER,
    STATIC FUNCTION cantidadDeDias ( fecha_inicio DATE, fecha_fin DATE ) RETURN NUMBER,
    CONSTRUCTOR FUNCTION FECHA ( fecha_inicio DATE, fecha_fin DATE ) RETURN SELF AS RESULT
);

/

CREATE OR REPLACE TYPE BODY FECHA AS
    STATIC FUNCTION validarFechas ( fecha_inicio DATE, fecha_fin DATE ) RETURN NUMBER
    IS
    BEGIN
        IF ((fecha_inicio > fecha_fin) OR (fecha_inicio = NULL) OR (fecha_fin = NULL)) THEN
            RAISE_APPLICATION_ERROR(-20001,'Formato de fechas inválido');
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END;


    STATIC FUNCTION cantidadDeDias ( fecha_inicio DATE, fecha_fin DATE ) RETURN NUMBER
    IS
    BEGIN
        RETURN fecha_fin - fecha_inicio + 1;
    END;
  
    CONSTRUCTOR FUNCTION FECHA ( fecha_inicio DATE, fecha_fin DATE ) RETURN SELF AS RESULT
    IS
    BEGIN
        IF (FECHA.validarFechas(fecha_inicio, fecha_fin) = 1) THEN
            SELF.fecha_inicio := fecha_inicio;
            SELF.fecha_fin := fecha_fin;
            SELF.cantidad_dias := FECHA.cantidadDeDias(fecha_inicio, fecha_fin);
            RETURN;
        END IF;
    END;
END;

/

CREATE OR REPLACE TYPE PRECIO AS OBJECT(
    precio_total NUMBER,
    
    STATIC FUNCTION validarCantidad (cantidad NUMBER) RETURN NUMBER,
    MEMBER PROCEDURE sumarPrecio (precio NUMBER),
    CONSTRUCTOR FUNCTION PRECIO (precio_base NUMBER) RETURN SELF AS RESULT
);

/

CREATE OR REPLACE TYPE BODY PRECIO AS
    STATIC FUNCTION validarCantidad (cantidad NUMBER) RETURN NUMBER
    IS
    BEGIN
        IF(cantidad >= 0) THEN
            RETURN 1;
        ELSE
            RAISE_APPLICATION_ERROR(-20016,'Error. La cantidad no puede ser negativa');
            RETURN 0;
        END IF;
    END;

    MEMBER PROCEDURE sumarPrecio (precio NUMBER)
    IS
    BEGIN
        SELF.PRECIO_TOTAL := SELF.PRECIO_TOTAL + precio;
    END;

    CONSTRUCTOR FUNCTION PRECIO (precio_base NUMBER) RETURN SELF AS RESULT
    IS
    BEGIN
        precio_total = 0;
        IF(PRECIO.validarCantidad(precio_base) = 1) THEN
            SELF.precio_total := precio_base;
            RETURN;
        END IF;
    END;
END;

/
