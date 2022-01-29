CREATE OR REPLACE PROCEDURE REPORTE5 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE, fecha_prox_mant IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT 
            'CRU-' || cr.tra_id "ID Crucero",
            tr.tra_foto "Foto",
            ma.man_fecha "Fecha mantenimiento",
            cr.cru_mant.fecha_prox_mant "Fecha de próximo mantenimiento",
            ma.man_descrip "Descripción mantenimiento",
            '$ ' || ma.man_costo "Costo"
        FROM MANTENIMIENTO ma
        INNER JOIN TRANSPORTE tr
            ON tr.tra_id = ma.tra_id
        INNER JOIN CRUCERO cr
            ON cr.tra_id = tr.tra_id
        WHERE   
            (TO_DATE(ma.man_fecha, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
            (TO_DATE(ma.man_fecha, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL) AND
            (TO_DATE(cr.cru_mant.fecha_prox_mant, 'DD-MM-YYYY') = TO_DATE(fecha_prox_mant, 'DD-MM-YYYY') OR fecha_prox_mant IS NULL)
        ORDER BY ma.man_fecha, cr.cru_mant.fecha_prox_mant;
END;

/
-- Tabla para el reporte 7
CREATE TABLE GASTOSVSINGRESOS(
    gvi_id NUMBER NOT NULL,
    gvi_fecha DATE NOT NULL,
    gvi_cat_servicio VARCHAR2(40) NOT NULL,
    gvi_costos NUMBER NOT NULL,
    gvi_ingresos NUMBER NOT NULL,
    gvi_ganancia NUMBER NOT NULL,
    
    CONSTRAINT pk_gvi PRIMARY KEY (gvi_id)
);

/
-- Buscar el ingreso que generó un servicio en específico en un rango de fechas en específico
CREATE OR REPLACE FUNCTION INGRESO_SERVICIO (fecha_ini DATE, fecha_f DATE, id_ser NUMBER) RETURN NUMBER
AS
    ingreso NUMBER; 
BEGIN 
    SELECT  
        paquetes*sprecio_unitario 
    INTO ingreso 
    FROM 
    (SELECT  
        se.ser_id AS sid, 
        se.ser_precio_unitario AS sprecio_unitario, 
        COUNT(pa.paq_id) AS paquetes 
    FROM SERVICIO se  
    INNER JOIN CARACTERISTICA ca  
    ON ca.ser_id = se.ser_id  
    INNER JOIN PAQUETE_TURISTICO pa  
    ON pa.paq_id = ca.paq_id  
    WHERE 
        ((pa.paq_fecha.fecha_inicio >= fecha_ini) OR fecha_ini IS NULL) AND 
        ((pa.paq_fecha.fecha_inicio <= fecha_f) OR fecha_f IS NULL) AND 
        ((se.ser_id = id_ser) OR id_ser IS NULL)
    GROUP BY se.ser_id,se.ser_precio_unitario); 
    RETURN ingreso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
END;

/

-- Procedimiento para insertar registros en la tabla usada en el reporte 7
CREATE OR REPLACE PROCEDURE INSERCIONES_GASTOSVSINGRESOS
AS 
    fecha_aux_ini DATE;   
    fecha_aux_fin DATE;  
    ingreso NUMBER; 
    CURSOR cvalores IS -- Cursor que contiene todas las disponibilidades con datos de sus servicios correspondientes  
        SELECT    
            di.dis_id AS dis_id,
            di.dis_fecha.fecha_inicio AS fecha_inicio,   
            di.dis_fecha.fecha_fin AS fecha_fin, 
            se.ser_id AS ser_id, 
            se.ser_nombre AS ser_nombre,  
            se.ser_costo_mensual  AS ser_costo_mensual          
        FROM DISPONIBILIDAD di   
        INNER JOIN SERVICIO se   
            ON di.ser_id = se.ser_id;  
    registro_cursor cvalores%rowtype;  
BEGIN   
    OPEN cvalores;  
    FETCH cvalores INTO registro_cursor;  
    WHILE cvalores%found  
        LOOP   
            fecha_aux_ini := ADD_MONTHS(trunc((registro_cursor.fecha_inicio),'month'),-1);  
            fecha_aux_fin := fecha_aux_ini;
            WHILE fecha_aux_fin < registro_cursor.fecha_fin
                LOOP   
                    fecha_aux_ini := ADD_MONTHS(fecha_aux_ini,1);   
                    fecha_aux_fin := ADD_MONTHS(fecha_aux_ini,1) - 1;  
                    IF (fecha_aux_fin > registro_cursor.fecha_fin) THEN  
                        fecha_aux_fin := registro_cursor.fecha_fin;  
                    END IF;  
                    ingreso := INGRESO_SERVICIO(fecha_aux_ini, fecha_aux_fin, registro_cursor.ser_id);
                    INSERT INTO GASTOSVSINGRESOS VALUES(gvi_id_seq.nextVal, fecha_aux_ini, registro_cursor.ser_nombre, registro_cursor.ser_costo_mensual, ingreso, ingreso - registro_cursor.ser_costo_mensual); 
                END LOOP;      
            FETCH cvalores INTO registro_cursor;  
        END LOOP;  
    CLOSE cvalores;  
END;

/

-- El parámetro ingresos sirve para filtrar ingresos bajos (como 0)
CREATE OR REPLACE PROCEDURE REPORTE7 (cursorReporte OUT SYS_REFCURSOR, cat_ser IN VARCHAR2, fecha IN DATE, ingresos IN NUMBER)
AS
    cont NUMBER;
BEGIN
    SELECT COUNT(gvi_id)
    INTO cont
    FROM GASTOSVSINGRESOS;

    execute INSERCIONES_GASTOSVSINGRESOS;

    OPEN cursorReporte FOR
        SELECT  
            to_char(gvi_fecha,'Month YYYY') "Mes", 
            gvi_cat_servicio "Categoría de Servicio", 
            '$ ' || SUM(gvi_costos) "Costos directos e indirectos (gastos)", 
            '$ ' || SUM(gvi_ingresos) "Ingresos recibidos por el servicio", 
            '$ ' || SUM(gvi_ganancia) "Ganancia"
        FROM GASTOSVSINGRESOS 
        WHERE 
            ((gvi_fecha = trunc((to_date(fecha)),'month')) OR fecha IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
            ((LOWER(gvi_cat_servicio) = LOWER(cat_ser)) OR cat_ser IS NULL) AND
            (gvi_ingresos > ingresos)
        GROUP BY gvi_fecha,gvi_cat_servicio -- Para agrupar nombres de servicio sin importar su destino
        ORDER BY gvi_fecha,gvi_cat_servicio;
    CLOSE cursorReporte;

    DELETE FROM GASTOSVSINGRESOS;
END;

/


