-- Inserciones en tablas con blob

create or replace PROCEDURE INSERTAR_BLOB_TRANSPORTE (id NUMBER, archivo VARCHAR2, nombre VARCHAR2)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        INSERT INTO TRANSPORTE VALUES (id,EMPTY_BLOB(),nombre) RETURNING tra_foto INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivo);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_DESTINO_FOTO (id NUMBER, nombre VARCHAR2, archivofoto VARCHAR2, descripcion VARCHAR2)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        INSERT INTO DESTINO_TURISTICO VALUES (id,nombre,EMPTY_BLOB(),NULL,descripcion) RETURNING des_foto INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivofoto);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_DESTINO_VIDEO (id NUMBER, archivovideo VARCHAR2)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        UPDATE DESTINO_TURISTICO
            SET des_video = EMPTY_BLOB() 
                WHERE des_id = id
                RETURNING des_video INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivovideo);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_DESTINO (id NUMBER, nombre VARCHAR2, archivofoto VARCHAR2, archivovideo VARCHAR2, descripcion VARCHAR2)
    IS
    BEGIN
        INSERTAR_BLOB_DESTINO_FOTO(id, nombre, archivofoto, descripcion);
        INSERTAR_BLOB_DESTINO_VIDEO(id, archivovideo);
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_PAIS (id NUMBER, nombre VARCHAR2, archivo VARCHAR2)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        INSERT INTO PAIS VALUES (id,nombre,EMPTY_BLOB()) RETURNING pai_bandera INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivo);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_EMPRESA (id NUMBER, nombre VARCHAR2, archivo VARCHAR2)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        INSERT INTO EMPRESA VALUES (id,nombre,EMPTY_BLOB()) RETURNING emp_logo INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivo);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;

/

create or replace PROCEDURE INSERTAR_BLOB_ALIANZA (id NUMBER, fe FECHA, archivo VARCHAR2, empfk NUMBER)
    IS
        V_blob BLOB;
        V_bfile BFILE;
    BEGIN
        INSERT INTO ALIANZA VALUES (id,fe,EMPTY_BLOB(),empfk) RETURNING ali_foto INTO V_blob;
        V_bfile := BFILENAME('IMAGES', archivo);
        DBMS_LOB.OPEN(V_bfile, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LOADFROMFILE(V_blob, V_bfile, SYS.DBMS_LOB.GETLENGTH(V_bfile));
        DBMS_LOB.CLOSE(V_bfile);
        COMMIT;
    END;