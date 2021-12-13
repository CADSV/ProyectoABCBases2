-- LISTAGG junta dos o más filas dependiendo del valor del GROUP BY 
-- Si se le coloca DISTINCT, solo seleccionará valores distintos de cada fila, por lo que no habrán repeticiones si queremos
-- juntar dos filas iguales y que se mantenga un solo valor. Esto es útil para los servicios, ya que cada paquete tiene diferentes servicios.
-- Se pueden hacer tablas temporales a través de subconsultas, y luego unir una tabla o varias tablas reales con esta tabla temporal (Como se observa en los Reportes 2 y 3)

CREATE OR REPLACE PROCEDURE REPORTE1 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE, id_des NUMBER, des_nomb VARCHAR2)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT 
            MIN(di.dis_creacion) "Fecha de creación",
            MIN(di.dis_fecha.fecha_inicio) "Fecha desde",
            MAX(di.dis_fecha.fecha_fin) "Fecha hasta",
            LISTAGG(DISTINCT de.des_nombre,'') "Destino",
            LISTAGG(DISTINCT '* '|| se.ser_nombre, chr(13) || chr(10) ) WITHIN GROUP (ORDER BY se.ser_nombre) "Servicios ofrecidos"
        FROM SERVICIO se
        INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
        INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = se.ser_id
        WHERE   
            (di.dis_fecha.fecha_inicio >= fecha_ini OR fecha_ini IS NULL) AND
            (di.dis_fecha.fecha_fin <= fecha_f OR fecha_f IS NULL) AND
            (se.des_id = id_des OR id_des IS NULL) AND
            (de.des_nombre = des_nombre OR des_nomb IS NULL)
        GROUP BY se.des_id;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE2 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT
            de.des_nombre "Destino turístico",
            sub.fecha_desde "Fecha desde",
            sub.fecha_hasta "Fecha hasta",
            de.des_foto "Fotos",
            de.des_video "Video",
            de.des_descripcion "Descripción"
        FROM DESTINO_TURISTICO de
        INNER JOIN ( -- Unimos destino con una tabla de subconsulta temporal
            SELECT 
                de.des_id,
                MIN(di.dis_fecha.fecha_inicio) as fecha_desde,
                MAX(di.dis_fecha.fecha_fin) as fecha_hasta
            FROM DESTINO_TURISTICO de
            INNER JOIN SERVICIO se
                ON se.des_id = de.des_id
            INNER JOIN DISPONIBILIDAD di
                ON di.ser_id = se.ser_id
            WHERE 
                (di.dis_fecha.fecha_inicio >= fecha_ini OR fecha_ini IS NULL) AND
                (di.dis_fecha.fecha_fin <= fecha_f OR fecha_f IS NULL)
            GROUP BY de.des_id
        ) sub ON sub.des_id = de.des_id;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE3 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE, id_des NUMBER, des_nomb VARCHAR2)
AS
BEGIN
    OPEN cursorReporte FOR 
        SELECT 
            sub.nombre_des "Destino turístico", 
            sub.inicio_fecha "Fecha inicio", 
            sub.fin_fecha "Fecha fin", 
            de.des_foto "Fotos", 
            sub.car "Características", 
            sub.costo "Costo" 
        FROM DESTINO_TURISTICO de 
        INNER JOIN ( 
            SELECT  
            LISTAGG(DISTINCT de.des_id,'') as id_des, 
            LISTAGG(DISTINCT de.des_nombre,'') as nombre_des,  
            LISTAGG(DISTINCT pa.paq_fecha.fecha_inicio,'') as inicio_fecha,  
            LISTAGG(DISTINCT pa.paq_fecha.fecha_fin,'') as fin_fecha, 
            LISTAGG(DISTINCT '* '|| se.ser_nombre, chr(13) || chr(10)) WITHIN GROUP (ORDER BY se.ser_nombre) as car, 
            LISTAGG(DISTINCT '$ ' || pa.paq_precio.precio_total || ' por persona','') as costo 
            FROM SERVICIO se 
            INNER JOIN CARACTERISTICA ca 
            ON ca.ser_id = se.ser_id 
            INNER JOIN PAQUETE_TURISTICO pa 
            ON pa.paq_id = ca.paq_id 
            INNER JOIN DESTINO_TURISTICO de 
            ON de.des_id = pa.des_id 
            WHERE   
                (pa.paq_fecha.fecha_inicio >= fecha_ini OR fecha_ini IS NULL) AND
                (pa.paq_fecha.fecha_fin <= fecha_f OR fecha_f IS NULL) AND
                (pa.des_id = id_des OR id_des IS NULL) AND
                (de.des_nombre = des_nombre OR des_nomb IS NULL)
            GROUP BY pa.paq_id 
        ) sub ON sub.id_des = de.des_id;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE4 (cursorReporte OUT SYS_REFCURSOR)
AS
BEGIN
    OPEN cursorReporte FOR 
        SELECT 

END;