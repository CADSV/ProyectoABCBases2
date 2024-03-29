alter session set "_ORACLE_SCRIPT"=true;

-- Drop de los usuarios
DROP USER armen CASCADE;
DROP USER ger_caracas CASCADE;
DROP USER turista CASCADE;


-- Drop de los roles
DROP ROLE ADMINISTRADOR;
DROP ROLE GERENTE;
DROP ROLE CLIENTE;


-- Creación de los roles.
CREATE ROLE ADMINISTRADOR;
CREATE ROLE GERENTE;
CREATE ROLE CLIENTE;


-- Asignación de permisos.
GRANT ALL PRIVILEGES TO ADMINISTRADOR;
GRANT CREATE SESSION TO GERENTE;
GRANT CREATE SESSION TO CLIENTE;


-- Permisos para el rol de administrador
GRANT ALL ON CLIENTE TO ADMINISTRADOR;
GRANT ALL ON SERVICIO TO ADMINISTRADOR;
GRANT ALL ON PAQUETE_TURISTICO TO ADMINISTRADOR;
GRANT ALL ON PAGO TO ADMINISTRADOR;
GRANT ALL ON MEDIO_PAGO TO ADMINISTRADOR;
GRANT ALL ON DESTINO_TURISTICO TO ADMINISTRADOR;
GRANT ALL ON EMPRESA TO ADMINISTRADOR;
GRANT ALL ON ASISTENCIA TO ADMINISTRADOR;
GRANT ALL ON OBSERVACION TO ADMINISTRADOR;
GRANT ALL ON MANTENIMIENTO TO ADMINISTRADOR;


-- Permisos para el rol de gerente
GRANT INSERT, SELECT, UPDATE ON CLIENTE TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON SERVICIO TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON PAQUETE_TURISTICO TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON PAGO TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON MEDIO_PAGO TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON DESTINO_TURISTICO TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON EMPRESA TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON ASISTENCIA TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON OBSERVACION TO GERENTE;
GRANT INSERT, SELECT, UPDATE ON MANTENIMIENTO TO GERENTE;
GRANT ALL ON DATOS TO GERENTE;
GRANT ALL ON TDA_MANTENIMIENTO TO GERENTE;
GRANT ALL ON PRECIO TO GERENTE;
GRANT ALL ON FECHA TO GERENTE;
GRANT ALL ON INSERTAR_BLOB_DESTINO TO GERENTE;
GRANT ALL ON INSERTAR_BLOB_EMPRESA TO GERENTE;


-- Permisos para el rol de cliente
GRANT INSERT, SELECT, UPDATE ON CLIENTE TO CLIENTE;
GRANT SELECT ON SERVICIO TO CLIENTE;
GRANT SELECT ON PAQUETE_TURISTICO TO CLIENTE;
GRANT INSERT, SELECT, UPDATE ON PAGO TO CLIENTE;
GRANT INSERT, SELECT, UPDATE ON MEDIO_PAGO TO CLIENTE;
GRANT SELECT ON DESTINO_TURISTICO TO CLIENTE;
GRANT SELECT ON ASISTENCIA TO CLIENTE;
GRANT INSERT, SELECT, UPDATE ON OBSERVACION TO CLIENTE;
GRANT ALL ON DATOS TO CLIENTE;



-- Creación de los usuarios
CREATE USER armen IDENTIFIED BY armen DEFAULT TABLESPACE USERS;
CREATE USER ger_caracas IDENTIFIED BY ger_caracas DEFAULT TABLESPACE USERS;
CREATE USER turista IDENTIFIED BY turista DEFAULT TABLESPACE USERS;


-- Acceso ilimitado a los usuarios
ALTER USER armen QUOTA UNLIMITED ON USERS;
ALTER USER ger_caracas QUOTA UNLIMITED ON USERS;
ALTER USER turista QUOTA UNLIMITED ON USERS;


-- Asignando roles a los usuarios
GRANT ADMINISTRADOR TO armen;
GRANT GERENTE TO ger_caracas;
GRANT CLIENTE TO turista;
