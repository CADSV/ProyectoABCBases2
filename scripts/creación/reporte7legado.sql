/* REPORTE 7 DE LEGADO, DEJADO POR RAZONES HISTORICAS
-- Buscar fecha minima y maxima de disponibilidad
CREATE OR REPLACE PROCEDURE MINMAX_FECHA_DISP (fecha_min OUT DATE, fecha_max OUT DATE)
AS
BEGIN
    SELECT MIN(di.dis_fecha.fecha_inicio)
    INTO fecha_min
    FROM DISPONIBILIDAD di;

    SELECT MAX(di.dis_fecha.fecha_fin)
    INTO fecha_fin
    FROM DISPONIBILIDAD di;
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
CREATE OR REPLACE PROCEDURE REPORTE7 (cursorReporte OUT SYS_REFCURSOR, cat_ser IN VARCHAR2, mesesano IN DATE, ingresos IN NUMBER)
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
            ((gvi_fecha = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
            ((LOWER(gvi_cat_servicio) = LOWER(cat_ser)) OR cat_ser IS NULL) AND
            (gvi_ingresos > ingresos)
        GROUP BY gvi_fecha,gvi_cat_servicio -- Para agrupar nombres de servicio sin importar su destino
        ORDER BY gvi_fecha,gvi_cat_servicio;
    CLOSE cursorReporte;

    DELETE FROM GASTOSVSINGRESOS;
END;

-- Apoyo para reportes mensuales, borrar luego
SELECT   
    the_month, 
    di.dis_fecha.fecha_inicio, 
    di.dis_fecha.fecha_fin, 
    se.ser_nombre 
FROM 
    (SELECT 
        add_months(trunc(sysdate-365, 'month'), level-1) the_month 
    FROM dual 
    CONNECT BY LEVEL <= 36) months 
LEFT JOIN DISPONIBILIDAD di 
    ON the_month >= trunc(di.dis_fecha.fecha_inicio, 'month') AND the_month <= di.dis_fecha.fecha_fin 
INNER JOIN SERVICIO se 
    ON se.ser_id = di.ser_id 
ORDER BY se.ser_id,the_month,di.dis_id;

*/

