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
/

CREATE OR REPLACE PROCEDURE REPORTE7 (cursorReporte OUT SYS_REFCURSOR, cat_ser IN VARCHAR2, mesesano IN DATE)
AS
    fecha_min DATE;
    fecha_max DATE;
BEGIN
    -- Obtener mínima y máxima fecha de compra (inicio de paquete)
    SELECT MIN(pa.paq_fecha.fecha_inicio)
    INTO fecha_min
    FROM PAQUETE_TURISTICO pa;

    SELECT MAX(pa.paq_fecha.fecha_inicio)
    INTO fecha_max
    FROM PAQUETE_TURISTICO pa;

    OPEN cursorReporte FOR
        SELECT  
            mesano "Mes",  
            sernom "Categoría de Servicio",   
            '$ ' || gastos "Costos directos e indirectos (gastos)",   
            '$ ' || (paquetes * precio) "Ingresos recibidos por el servicio",   
            '$ ' || ((paquetes * precio) - gastos) "Ganancia"  
        FROM  
            (SELECT     
                to_char(mes,'Month YYYY') AS mesano,  
                se.ser_nombre AS sernom,   
                SUM(se.ser_costo_mensual) AS gastos,   
                SUM(se.ser_precio_unitario) AS precio,  
                COUNT(pa.paq_id) AS paquetes  
            FROM   
                (SELECT   
                    add_months(trunc(to_date(fecha_min), 'month'), level-1) mes  
                FROM dual   
                CONNECT BY LEVEL <= floor(MONTHS_BETWEEN(fecha_max,fecha_min)))  
            LEFT JOIN PAQUETE_TURISTICO pa   
                ON mes = trunc(pa.paq_fecha.fecha_inicio, 'month') 
            INNER JOIN CARACTERISTICA ca    
                ON ca.paq_id = pa.paq_id 
            INNER JOIN SERVICIO se   
                ON se.ser_id = ca.ser_id       
            WHERE   
                ((mes = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes  
                ((LOWER(se.ser_nombre) = LOWER(cat_ser)) OR cat_ser IS NULL) 
            GROUP BY mes, se.ser_nombre  
            ORDER BY mes, - SUM(se.ser_precio_unitario) * COUNT(pa.paq_id) + SUM(se.ser_costo_mensual));
END;

/

CREATE OR REPLACE PROCEDURE REPORTE9 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT 
            al.ali_fecha.fecha_inicio,
            em.emp_nombre,
            em.emp_logo,
            al.ali_foto
        FROM ALIANZA al
        INNER JOIN PROVEEDOR pr
            ON pr.emp_id = al.emp_id
        INNER JOIN EMPRESA em
            ON em.emp_id = pr.emp_id
        WHERE   
            (TO_DATE(al.ali_fecha.fecha_inicio, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
            (TO_DATE(al.ali_fecha.fecha_inicio, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL)
        ORDER BY al.ali_fecha.fecha_inicio,em.emp_nombre;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE11 (cursorReporte OUT SYS_REFCURSOR, mesesano IN DATE, nom_pais IN VARCHAR2)
AS
    fecha_min DATE;
    fecha_max DATE;
BEGIN
    -- Obtener mínima y máxima fecha de compra (inicio de paquete)
    SELECT MIN(pa.paq_fecha.fecha_inicio)
    INTO fecha_min
    FROM PAQUETE_TURISTICO pa;

    SELECT MAX(pa.paq_fecha.fecha_inicio)
    INTO fecha_max
    FROM PAQUETE_TURISTICO pa;

    -- Debemos obtener la bandera por fuera ya que no se puede agrupar por BLOB
    OPEN cursorReporte FOR
        SELECT  
            mesano "Fecha",  
            pi.pai_bandera "Foto País",   
            paisnom "País",   
            unicom "Unidades compradas"  
        FROM 
                (SELECT     
                    to_char(mes,'Month YYYY') mesano,   
                    pi.pai_nombre paisnom,   
                    COUNT(pa.paq_id) unicom 
                FROM   
                    (SELECT   
                        add_months(trunc(to_date(fecha_min), 'month'), level-1) mes  
                    FROM dual   
                    CONNECT BY LEVEL <= floor(MONTHS_BETWEEN(fecha_max,fecha_min))) 
                LEFT JOIN PAQUETE_TURISTICO pa   
                    ON mes = trunc(pa.paq_fecha.fecha_inicio, 'month') 
                INNER JOIN PAGO pg   
                    ON pg.pag_id = pa.pag_id   
                INNER JOIN CLIENTE cl  
                    ON cl.cli_id = pg.cli_id  
                INNER JOIN PAIS pi  
                    ON pi.pai_id = cl.pai_id 
                WHERE
                    ((mesano = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
                    ((LOWER(nom_pais) = LOWER(paisnom)) OR nom_pais IS NULL)
                GROUP BY mes,pi.pai_nombre) 
        INNER JOIN PAIS pi 
            ON pi.pai_nombre = paisnom 
        ORDER BY mesano,paisnom;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE13 (cursorReporte OUT SYS_REFCURSOR, escala IN NUMBER)
AS
    fecha_min DATE;
    fecha_max DATE;
BEGIN
    -- Obtener mínima y máxima fecha de observacion
    SELECT MIN(ob.obs_fecha)
    INTO fecha_min
    FROM OBSERVACION ob;

    SELECT MAX(ob.obs_fecha)
    INTO fecha_max
    FROM OBSERVACION ob;

    OPEN cursorReporte FOR
        SELECT      
            to_char(mes,'Month YYYY') "Mes", 
            se.ser_nombre "Categoría de Servicio",
            CASE -- Convertir promedio de calificaciones en carita
                WHEN (AVG(ob.obs_calif)) <= 1.5
                    THEN ':('
                WHEN (AVG(ob.obs_calif)) > 1.5 AND (AVG(ob.obs_calif)) < 2.5
                    THEN ':|'
                WHEN (AVG(ob.obs_calif)) >= 2.5
                    THEN ':)'
                END "Escala de Calificación",
            -- ROUND(AVG(ob.obs_calif)) "Escala de Calificación",
            LISTAGG(DISTINCT '- ' || ob.obs_texto, chr(13) || chr(10)) WITHIN GROUP (ORDER BY ob.obs_texto) "Observaciones"
        FROM   
            (SELECT   
                add_months(trunc(to_date(fecha_min), 'month'), level-1) mes  
            FROM dual   
            CONNECT BY LEVEL <= floor(MONTHS_BETWEEN(fecha_max,fecha_min))) 
        LEFT JOIN OBSERVACION ob   
            ON mes = trunc(ob.obs_fecha, 'month') 
        INNER JOIN SERVICIO se   
            ON se.ser_id = ob.ser_id   
        WHERE
            ((mes = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
            ((ROUND(escala) = ROUND(AVG(ob.obs_calif)) OR escala IS NULL)
        GROUP BY mes,se.ser_nombre
        ORDER BY mes,se.ser_nombre;
END,

