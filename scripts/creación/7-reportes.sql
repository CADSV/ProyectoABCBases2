CREATE OR REPLACE PROCEDURE REPORTE_1 (cursorReporte OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN cursorReporte FOR SELECT di.dis_creacion, di.dis_fecha.fecha_inicio, di.dis_fecha.fecha_fin, de.des_nombre, se.ser_nombre
    FROM DISPONIBILIDAD di, 

END;

CREATE OR REPLACE PROCEDURE REPORTE_2 (cursorReporte OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN cursorReporte FOR SELECT de.des_nombre, di.dis_fecha.fecha_inicio, di.dis_fecha.fecha_fin, de.des_foto, de.des_video, de.des_descripcion
    FROM 

END;

CREATE OR REPLACE PROCEDURE REPORTE_3 (cursorReporte OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN cursorReporte FOR SELECT de.des_nombre, pa.paq_fecha.fecha_inicio, pa.paq_fecha.fecha_fin, des.des_foto, se.ser_nombre, pa.paq_precio.precio_total
    FROM PAQUETE_TURISTICO paq

END;

CREATE OR REPLACE PROCEDURE REPORTE_4 (cursorReporte OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN cursorReporte FOR SELECT 

END;