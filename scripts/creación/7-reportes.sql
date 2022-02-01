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
            (TO_DATE(di.dis_fecha.fecha_inicio, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
            (TO_DATE(di.dis_fecha.fecha_fin, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL) AND
            (se.des_id = id_des OR id_des IS NULL) AND
            (de.des_nombre = des_nomb OR des_nomb IS NULL)
        GROUP BY se.des_id
        ORDER BY MIN(di.dis_creacion);
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
            GROUP BY de.des_id
            ORDER BY fecha_desde
        ) sub ON sub.des_id = de.des_id
        WHERE 
            (TO_DATE(sub.fecha_desde, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
            (TO_DATE(sub.fecha_hasta, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL);
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
                LISTAGG(DISTINCT '- '|| se.ser_nombre, chr(13) || chr(10)) WITHIN GROUP (ORDER BY se.ser_nombre) as car, 
                LISTAGG(DISTINCT '$ ' || pa.paq_precio.precio_total || ' por persona','') as costo 
            FROM SERVICIO se 
            INNER JOIN CARACTERISTICA ca 
                ON ca.ser_id = se.ser_id 
            INNER JOIN PAQUETE_TURISTICO pa 
                ON pa.paq_id = ca.paq_id 
            INNER JOIN DESTINO_TURISTICO de 
                ON de.des_id = pa.des_id 
            WHERE   
                (TO_DATE(pa.paq_fecha.fecha_inicio, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
                (TO_DATE(pa.paq_fecha.fecha_fin, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL) AND
                (pa.des_id = id_des OR id_des IS NULL) AND
                (de.des_nombre = des_nomb OR des_nomb IS NULL)
            GROUP BY pa.paq_id 
        ) sub ON sub.id_des = de.des_id
        ORDER BY sub.inicio_fecha;
END;

/

CREATE OR REPLACE PROCEDURE REPORTE4 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE, nombre_disp VARCHAR2)
AS
BEGIN
    OPEN cursorReporte FOR 
        SELECT 
            de.des_nombre "Destino turistico",
            pa.paq_fecha.fecha_inicio "Fecha inicio",
            pa.paq_fecha.fecha_fin "Fecha fin",
            de.des_foto "Fotos",
            sub1.car "Características",
            '$ ' || pa.paq_precio.precio_total || ' por persona' "Costo",
            cl.cli_datos.dat_primer_nombre || ' ' || cl.cli_datos.dat_segundo_nombre || ' ' || cl.cli_datos.dat_primer_apellido || ' ' || cl.cli_datos.dat_segundo_apellido "Nombre Cliente",
            cl.cli_datos.dat_email "Email",
            sub2.medios_de_pago "Forma de Pago",
            pg.pag_canal "Canal utilizado",
            pg.pag_dispositivo "Dispositivo utilizado"
        FROM PAGO pg
        INNER JOIN PAQUETE_TURISTICO pa
            ON pa.pag_id = pg.pag_id
        INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = pa.des_id
        INNER JOIN CLIENTE cl
            ON cl.cli_id = pg.cli_id
        INNER JOIN (
            SELECT
                pa.paq_id,
                LISTAGG(DISTINCT se.ser_nombre, chr(13) || chr(10)) WITHIN GROUP (ORDER BY se.ser_nombre) as car
            FROM SERVICIO se
            INNER JOIN CARACTERISTICA ca 
                ON ca.ser_id = se.ser_id 
            INNER JOIN PAQUETE_TURISTICO pa 
                ON pa.paq_id = ca.paq_id 
            GROUP BY pa.paq_id
        ) sub1 ON sub1.paq_id = pa.paq_id
        INNER JOIN (
            SELECT
                mp.pag_id,
                LISTAGG('$ '|| ROUND(mp.med_monto,2) ||' - '|| mp.med_nombre ,chr(13) || chr(10) ) WITHIN GROUP (ORDER BY mp.med_monto) as medios_de_pago
            FROM MEDIO_PAGO mp
            GROUP BY mp.pag_id
        ) sub2 ON sub2.pag_id = pg.pag_id
        WHERE 
            (TO_DATE(pa.paq_fecha.fecha_inicio, 'DD-MM-YYYY') >= TO_DATE(fecha_ini, 'DD-MM-YYYY') OR fecha_ini IS NULL) AND
            (TO_DATE(pa.paq_fecha.fecha_fin, 'DD-MM-YYYY') <= TO_DATE(fecha_f, 'DD-MM-YYYY') OR fecha_f IS NULL) AND
            (pg.pag_dispositivo = nombre_disp OR nombre_disp IS NULL)
        ORDER BY pa.paq_fecha.fecha_inicio;
END;


/

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

CREATE OR REPLACE PROCEDURE REPORTE6 (cursorReporte OUT SYS_REFCURSOR, fecha_mes IN DATE, categoria_servicio VARCHAR2)
AS
BEGIN
    OPEN cursorReporte FOR
    SELECT
        mesano "Mes",
        catser "Categoría de Servicio",
        deman "% Demanda del Servicio",
        cantid "Cantidad de clientes que lo han solicitado"  
    FROM
        (SELECT
            to_char(car.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY') mesano,
            LISTAGG(DISTINCT ser.SER_NOMBRE, '') catser,
            LISTAGG(DISTINCT CONCAT(ROUND(subg.cant_serv*100/subg.cant_ser_mes,2),'%'),'') deman,
            COUNT(car.SER_ID) cantid
        FROM SERVICIO ser
        INNER JOIN CARACTERISTICA car on ser.SER_ID = car.SER_ID
        INNER JOIN (
            SELECT
                COUNT(c.SER_ID) as cant_serv,
                LISTAGG(DISTINCT c.SER_ID, '') as id_paq,
                to_char(c.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY') as fecha,
                LISTAGG(DISTINCT sub.cant_mes) as cant_ser_mes
            FROM SERVICIO s
            INNER JOIN CARACTERISTICA c ON s.SER_ID = c.SER_ID

            INNER JOIN (
            SELECT
                to_char(carec.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY') as mes,
                COUNT(carec.SER_ID)  as cant_mes
            FROM CARACTERISTICA carec
            GROUP BY to_char(carec.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY')
            ) sub ON sub.mes = to_char(c.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY')

            GROUP BY s.SER_NOMBRE, to_char(c.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY')
            ORDER BY to_char(c.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY')
        ) subg ON (subg.id_paq = car.SER_ID AND subg.fecha = to_char(car.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY'))

        GROUP BY ser.SER_NOMBRE, to_char(car.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY')
        ORDER BY to_char(car.CAR_FECHA.FECHA_INICIO, 'MONTH YYYY'))
        
        WHERE
            ((LOWER(catser) = LOWER(categoria_servicio)) OR categoria_servicio IS NULL) AND
            (mesano = to_char(fecha_mes, 'MONTH YYYY') OR fecha_mes IS NULL);
END;

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
            '$ ' || ((paquetes * precio) - gastos) "Ganancia",
            gastos gastosgraf,
            (paquetes * precio) ingresosgraf
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

    CREATE OR REPLACE PROCEDURE REPORTE8 (cursorReporte OUT SYS_REFCURSOR, fecha_mes IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
       SELECT
            to_char(pag.PAG_FECHA, 'MONTH YYYY') "Mes",
            LISTAGG(DISTINCT '* '|| med.MED_NOMBRE || ROUND(subg.cant_medio*100/subg.cant_mes,2) ||'%', chr(13) || chr(10) ) WITHIN GROUP (ORDER BY med.MED_NOMBRE) "Medio de pago y porcentaje del mismo"

        FROM PAGO pag
        INNER JOIN MEDIO_PAGO med ON pag.PAG_ID = med.PAG_ID

        INNER JOIN (
            SELECT
                count(m.MED_ID) as cant_medio,
                m.MED_NOMBRE as nombre_medio,
                LISTAGG(DISTINCT sub.mes) as fecha,
                LISTAGG(DISTINCT sub.total_medio_mes) as cant_mes

            FROM MEDIO_PAGO m
            INNER JOIN PAGO p on p.PAG_ID = m.PAG_ID
            INNER JOIN (
                    SELECT
                        count(me.MED_ID) as total_medio_mes,
                        to_char(pa.PAG_FECHA, 'MONTH YYYY') as mes

                    FROM MEDIO_PAGO me
                    INNER JOIN PAGO pa on pa.PAG_ID = me.PAG_ID
                    GROUP BY to_char(pa.PAG_FECHA, 'MONTH YYYY')
                ) sub ON sub.mes = to_char(p.PAG_FECHA, 'MONTH YYYY')

        GROUP BY to_char(p.PAG_FECHA, 'MONTH YYYY'), m.MED_NOMBRE
    ) subg ON (subg.nombre_medio = med.MED_NOMBRE AND subg.fecha = to_char(pag.PAG_FECHA, 'MONTH YYYY'))

        WHERE to_char(pag.PAG_FECHA, 'MONTH YYYY') = to_char(fecha_mes, 'MONTH YYYY') OR fecha_mes IS NULL

        GROUP BY to_char(pag.PAG_FECHA, 'MONTH YYYY')
        ORDER BY to_char(pag.PAG_FECHA, 'MONTH YYYY');

END;

/

CREATE OR REPLACE PROCEDURE REPORTE9 (cursorReporte OUT SYS_REFCURSOR, fecha_ini IN DATE, fecha_f IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT 
            al.ali_fecha.fecha_inicio "Fecha inicio alianza",
            em.emp_nombre "Nombre Proveedor",
            em.emp_logo "Logo",
            al.ali_foto "Foto"
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

CREATE OR REPLACE PROCEDURE REPORTE10 (cursorReporte OUT SYS_REFCURSOR, fecha_mes IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT
            to_char(ven.VEN_FECHA, 'MONTH YYYY') "Fecha",
            emp.EMP_NOMBRE "Competencia",
            emp.EMP_LOGO "Foto Logo",
            NVL(subg.ventas_estrella,0) "Ventas Estrella Caribeña",
            ven.VEN_CANTIDAD "Ventas de Competencia"

        FROM EMPRESA emp
        INNER JOIN COMPETIDOR comp ON emp.EMP_ID = comp.EMP_ID
        INNER JOIN VENTA ven ON comp.EMP_ID = ven.EMP_ID
        LEFT JOIN (
            SELECT
                COUNT(paq.PAQ_ID) as ventas_estrella,
                to_char(paq.PAQ_FECHA.FECHA_INICIO, 'MONTH YYYY') as fecha
            FROM PAQUETE_TURISTICO paq
            GROUP BY to_char(paq.PAQ_FECHA.FECHA_INICIO, 'MONTH YYYY')
        ) subg ON subg.fecha = to_char(ven.VEN_FECHA, 'MONTH YYYY')

        WHERE to_char(ven.VEN_FECHA, 'MONTH YYYY') = to_char(fecha_mes, 'MONTH YYYY') OR fecha_mes IS NULL
        ORDER BY ven.VEN_FECHA ;

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
            unicom || ' Unidades' "Unidades compradas"  
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
                    ((mes = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
                    ((LOWER(nom_pais) = LOWER(pi.pai_nombre)) OR nom_pais IS NULL)
                GROUP BY mes,pi.pai_nombre) 
        INNER JOIN PAIS pi 
            ON pi.pai_nombre = paisnom 
        ORDER BY mesano,paisnom;
END;

/

   CREATE OR REPLACE PROCEDURE REPORTE12 (cursorReporte OUT SYS_REFCURSOR, fecha_mes IN DATE)
AS
BEGIN
    OPEN cursorReporte FOR
        SELECT
            to_char(pag.PAG_FECHA, 'MONTH YYYY') "Mes",
            LISTAGG(DISTINCT '* '|| PAG.PAG_CANAL || ROUND(subg.cant_por_canal*100/subg.cant_mensual,2) ||'%', chr(13) || chr(10) ) WITHIN GROUP (ORDER BY pag.PAG_CANAL) "Canal utilizado para las ventas"

        FROM PAGO pag
        INNER JOIN(
            SELECT
                COUNT(pa.PAG_CANAL) as cant_por_canal,
                pa.PAG_CANAL as nombre_canal,
                LISTAGG(DISTINCT sub.mes, '') as fecha,
                LISTAGG(DISTINCT sub.cant_mes,'') as cant_mensual

            FROM PAGO pa
            INNER JOIN (
                SELECT
                    to_char(p.PAG_FECHA, 'MONTH YYYY') as mes,
                    COUNT(p.PAG_CANAL) as cant_mes

                FROM PAGO p
                GROUP BY to_char(p.PAG_FECHA, 'MONTH YYYY')
            ) sub ON sub.mes = to_char(pa.PAG_FECHA, 'MONTH YYYY')

            GROUP BY to_char(pa.PAG_FECHA, 'MONTH YYYY'), pa.PAG_CANAL
        ) subg ON ((subg.nombre_canal = pag.PAG_CANAL) AND (subg.fecha = to_char(pag.PAG_FECHA, 'MONTH YYYY')))

        WHERE to_char(pag.PAG_FECHA, 'MONTH YYYY') = to_char(fecha_mes, 'MONTH YYYY') OR fecha_mes IS NULL
        group by to_char(pag.PAG_FECHA, 'MONTH YYYY')
        ORDER BY to_char(pag.PAG_FECHA,'MONTH YYYY');

END;

/

CREATE OR REPLACE PROCEDURE REPORTE13 (cursorReporte OUT SYS_REFCURSOR, mesesano IN DATE, escalacara IN VARCHAR2)
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
            mesano "Mes", 
            catser "Categoría de Servicio",
            escal "Escala de Calificación",
            obser "Observaciones"
        FROM
            (SELECT      
                to_char(mes,'Month YYYY') mesano, 
                se.ser_nombre catser,
                CASE -- Convertir promedio de calificaciones en carita
                    WHEN (AVG(ob.obs_calif)) <= 1.5
                        THEN ':('
                    WHEN (AVG(ob.obs_calif)) > 1.5 AND (AVG(ob.obs_calif)) < 2.5
                        THEN ':|'
                    WHEN (AVG(ob.obs_calif)) >= 2.5
                        THEN ':-)'
                    END escal,
                -- ROUND(AVG(ob.obs_calif)) "Escala de Calificación",
                LISTAGG(DISTINCT '- ' || ob.obs_texto, chr(13) || chr(10)) WITHIN GROUP (ORDER BY ob.obs_texto) obser
            FROM   
                (SELECT   
                    add_months(trunc(to_date(fecha_min), 'month'), level-1) mes  
                FROM dual   
                CONNECT BY LEVEL <= floor(MONTHS_BETWEEN(fecha_max,fecha_min))) 
            LEFT JOIN OBSERVACION ob   
                ON mes = trunc(ob.obs_fecha, 'month') 
            INNER JOIN SERVICIO se   
                ON se.ser_id = ob.ser_id   
            GROUP BY mes,se.ser_nombre
            ORDER BY mes,se.ser_nombre)
        WHERE
            ((mesano = trunc((to_date(mesesano)),'month')) OR mesesano IS NULL) AND -- Convierte la fecha a la fecha del primer día de su mes
            ((escalacara = escal) OR escalacara IS NULL);
END;
