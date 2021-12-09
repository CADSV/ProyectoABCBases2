-- NIVEL 1 NIVEL 1 NIVEL 1 NIVEL 1 NIVEL 1 NIVEL 1 NIVEL 1 NIVEL 1 

CREATE TABLE TRANSPORTE(
    tra_id NUMBER PRIMARY KEY,
    tra_foto BLOB DEFAULT EMPTY_BLOB(),
    tra_nombre VARCHAR2(40) NOT NULL
);

/



CREATE TABLE CRUCERO(
    tra_id NUMBER PRIMARY KEY,
    cru_mant TDA_MANTENIMIENTO NOT NULL,
    
    CONSTRAINT FK_CRUCERO FOREIGN KEY (tra_id) REFERENCES TRANSPORTE(tra_id)
);

/



CREATE TABLE TERRESTRE(
    tra_id NUMBER PRIMARY KEY,
    
    CONSTRAINT FK_TERRESTRE FOREIGN KEY (tra_id) REFERENCES TRANSPORTE(tra_id)
);

/



CREATE TABLE DESTINO_TURISTICO(
    des_id NUMBER PRIMARY KEY,
    des_nombre VARCHAR2(40) NOT NULL,
    des_foto BLOB DEFAULT EMPTY_BLOB(),
    des_video BLOB DEFAULT EMPTY_BLOB(),
    des_descripcion VARCHAR2(200) NOT NULL
);

/



CREATE TABLE PAIS (
    pai_id NUMBER PRIMARY KEY NOT NULL,
    pai_nombre VARCHAR2(40) NOT NULL,
    pai_bandera BLOB DEFAULT EMPTY_BLOB()
);

/



CREATE TABLE EMPRESA (
    emp_id NUMBER PRIMARY KEY NOT NULL,
    emp_nombre VARCHAR2(40) NOT NULL,
    emp_logo BLOB DEFAULT EMPTY_BLOB()
);

/



CREATE TABLE COMPETIDOR(
    emp_id NUMBER PRIMARY KEY,
    
    CONSTRAINT fk_emp_id_comp FOREIGN KEY (emp_id) REFERENCES EMPRESA(emp_id)
);

/



CREATE TABLE PROVEEDOR(
    emp_id NUMBER PRIMARY KEY,
    
    CONSTRAINT fk_emp_id_prov FOREIGN KEY (emp_id) REFERENCES EMPRESA(emp_id)
);

/



-- NIVEL 2 NIVEL 2 NIVEL 2 NIVEL 2 NIVEL 2 NIVEL 2 NIVEL 2 NIVEL 2 

CREATE TABLE MANTENIMIENTO(
    man_id NUMBER PRIMARY KEY,
    man_fecha DATE NOT NULL,
    man_descrip VARCHAR2(200) NOT NULL,
    man_costo NUMBER NOT NULL,
    tra_id NUMBER NOT NULL,
    CONSTRAINT FK_MANTENIMIENTO FOREIGN KEY (tra_id) REFERENCES CRUCERO(tra_id)
);

/



CREATE TABLE CLIENTE(
    cli_id NUMBER PRIMARY KEY NOT NULL,
    cli_datos DATOS NOT NULL,
    pai_id NUMBER NOT NULL,
    
    CONSTRAINT fk_cliente_pais FOREIGN KEY (pai_id) REFERENCES PAIS (pai_id)
);

/



CREATE TABLE VENTA(
    ven_id NUMBER PRIMARY KEY NOT NULL,
    ven_fecha DATE NOT NULL,
    ven_cantidad NUMBER NOT NULL,
    emp_id NUMBER NOT NULL,
    
    CONSTRAINT fk_emp_id_venta FOREIGN KEY (emp_id) REFERENCES COMPETIDOR(emp_id)
);


/



CREATE TABLE ALIANZA(
    ali_id NUMBER PRIMARY KEY NOT NULL,
    ali_fecha FECHA,
    emp_id NUMBER NOT NULL,
    
    CONSTRAINT fk_emp_id_ali FOREIGN KEY (emp_id) REFERENCES PROVEEDOR(emp_id)
);

/



-- NIVEL 3 NIVEL 3 NIVEL 3 NIVEL 3 NIVEL 3 NIVEL 3 NIVEL 3 NIVEL 3 

CREATE TABLE FAMILIAR(
    cli_id1 NUMBER,
    cli_id2 NUMBER,
    
    CONSTRAINT no_familiar_consigo_mismo CHECK (cli_id1 != cli_id2),
    CONSTRAINT pk_familiar PRIMARY KEY (cli_id1, cli_id2),
    CONSTRAINT fk_familiar_cliente1 FOREIGN KEY (cli_id1) REFERENCES CLIENTE (cli_id),
    CONSTRAINT fk_familiar_cliente2 FOREIGN KEY (cli_id2) REFERENCES CLIENTE (cli_id)
);

/

CREATE TABLE SERVICIO(
    ser_id NUMBER PRIMARY KEY NOT NULL,
    ser_nombre VARCHAR2(40) NOT NULL,
    ser_foto BLOB DEFAULT EMPTY_BLOB(),
    ser_costo_mensual NUMBER NOT NULL,
    ser_precio_unitario NUMBER NOT NULL,
    ser_duracion NUMBER,
    des_id NUMBER NOT NULL,
    tra_id NUMBER,
    ali_id NUMBER,
    
    CONSTRAINT fk_tra_id_servi FOREIGN KEY (tra_id) REFERENCES TRANSPORTE(tra_id),
    CONSTRAINT fk_des_id_servi FOREIGN KEY (des_id) REFERENCES DESTINO_TURISTICO(des_id),
    CONSTRAINT fk_ali_id_servi FOREIGN KEY (ali_id) REFERENCES ALIANZA(ali_id),
    CONSTRAINT ser_cantidad_positiva CHECK (ser_precio_unitario >= 0 AND ser_costo_mensual >= 0)
);

/




CREATE TABLE PCR(
    pcr_id NUMBER PRIMARY KEY NOT NULL,
    pcr_fecha DATE NOT NULL,
    pcr_status NUMBER(1) NOT NULL,
    cli_id NUMBER NOT NULL,
    
    CONSTRAINT fk_pcr_cliente FOREIGN KEY (cli_id) REFERENCES CLIENTE(cli_id)
);

/



CREATE TABLE PAGO(
    pag_id NUMBER PRIMARY KEY NOT NULL,
    pag_canal VARCHAR2(40) NOT NULL,
    pag_dispositivo VARCHAR2(40) NOT NULL,
    pag_fecha DATE NOT NULL,
    pag_monto_total NUMBER NOT NULL,
    cli_id NUMBER NOT NULL,
    
    CONSTRAINT fk_cli_id_pago FOREIGN KEY (cli_id) REFERENCES CLIENTE(cli_id)
);


/



-- NIVEL 4 NIVEL 4 NIVEL 4 NIVEL 4 NIVEL 4 NIVEL 4 NIVEL 4 NIVEL 4 

CREATE TABLE DISPONIBILIDAD(
    dis_id NUMBER PRIMARY KEY,
    dis_fecha FECHA NOT NULL,
    dis_cantidad_disp NUMBER NOT NULL,
    ser_id NUMBER NOT NULL,
    
    CONSTRAINT fk_disponibilidad_servicio FOREIGN KEY (ser_id) REFERENCES SERVICIO (ser_id)
);

/



CREATE TABLE OBSERVACION(
    obs_id NUMBER PRIMARY KEY,
    obs_calif NUMBER NOT NULL,
    obs_texto VARCHAR(200),
    obs_fecha DATE NOT NULL,
    ser_id NUMBER NOT NULL,
    cli_id NUMBER NOT NULL,
    
    CONSTRAINT intervalo_calificacion CHECK (obs_calif >= 0 AND obs_calif <= 3),
    CONSTRAINT fk_observacion_servicio FOREIGN KEY (ser_id) REFERENCES SERVICIO (ser_id),
    CONSTRAINT fk_observacion_cliente FOREIGN KEY (cli_id) REFERENCES CLIENTE (cli_id)
);

/



CREATE TABLE PAQUETE_TURISTICO(
    paq_id NUMBER PRIMARY KEY,
    paq_precio PRECIO NOT NULL,
    paq_fecha FECHA NOT NULL,
    pag_id NUMBER NOT NULL,
    des_id NUMBER NOT NULL,
    
    CONSTRAINT fk_paquete_pago FOREIGN KEY (pag_id) REFERENCES PAGO (pag_id),
    CONSTRAINT fk_paquete_destino FOREIGN KEY (des_id) REFERENCES DESTINO_TURISTICO (des_id)
  
);

/



CREATE TABLE MEDIO_PAGO(
    med_id NUMBER PRIMARY KEY NOT NULL,
    med_nombre VARCHAR2(40) NOT NULL,
    med_monto NUMBER NOT NULL,
    pag_id NUMBER NOT NULL,
    
    CONSTRAINT fk_pag_id_med FOREIGN KEY (pag_id) REFERENCES PAGO(pag_id)
);

/



CREATE TABLE ASISTENCIA(
    asi_id NUMBER PRIMARY KEY NOT NULL,
    asi_asistio NUMBER(1) DEFAULT 0 NOT NULL,
    asi_fecha DATE,
    cli_id NUMBER NOT NULL,
    ser_id NUMBER NOT NULL,
    
    CONSTRAINT fk_cli_id_asi FOREIGN KEY (cli_id) REFERENCES CLIENTE(cli_id),
    CONSTRAINT fk_ser_id_asi FOREIGN KEY (ser_id) REFERENCES SERVICICO(ser_id)
);

/



-- NIVEL 5 NIVEL 5 NIVEL 5 NIVEL 5 NIVEL 5 NIVEL 5 NIVEL 5 NIVEL 5

CREATE TABLE CARACTERISTICA(
    paq_id NUMBER NOT NULL,
    ser_id NUMBER NOT NULL,
    car_fecha FECHA NOT NULL,
    
    CONSTRAINT pk_caracteristica PRIMARY KEY (paq_id, ser_id),
    CONSTRAINT fk_paq_id_car FOREIGN KEY (paq_id) REFERENCES PAQUETE_TURISTICO(paq_id),
    CONSTRAINT fk_ser_id_car FOREIGN KEY (ser_id) REFERENCES SERVICIO(ser_id)
);

/



CREATE TABLE PERTENENCIA(
    cli_id NUMBER NOT NULL,
    paq_id NUMBER NOT NULL,
    
    CONSTRAINT fk_pert_cliente FOREIGN KEY (cli_id) REFERENCES CLIENTE(cli_id),
    CONSTRAINT fk_pert_paquete FOREIGN KEY (paq_id) REFERENCES PAQUETE_TURISTICO(paq_id)
);

/
