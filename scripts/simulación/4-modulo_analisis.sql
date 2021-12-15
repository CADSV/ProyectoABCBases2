-- Modulo de Análisis 
CREATE OR REPLACE PACKAGE MODULO_ANALISIS IS
    PROCEDURE analisis_servicios(fecha_ini DATE, fecha_f DATE);
END;

/

CREATE OR REPLACE PACKAGE BODY MODULO_ANALISIS AS
    PROCEDURE analisis_servicios(fecha_ini DATE, fecha_f DATE)
    IS
        cont NUMBER;
        idali NUMBER;
        idserv NUMBER; 
        iddest NUMBER;
        iddest_menosdem NUMBER;
        fecha_ini_disp DATE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------');
        dbms_output.put_line('');
        dbms_output.put_line('');
        dbms_output.put_line('******************************');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('*    ANALIZANDO SERVICIOS    *');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('******************************');
        dbms_output.put_line('');
        dbms_output.put_line('');
        dbms_output.put_line('Realizadas las compras y las observaciones de diferentes servicios, se procede a analizarlos:');
        dbms_output.put_line('');
        dbms_output.put_line('Se agregarán 6 servicios y se eliminarán 6:');
        dbms_output.put_line('');

        cont := 1;
        -- 3 Servicios más demandados y disponibles actualmente
        FOR servicio_mas_demandado IN
            (SELECT se.ser_nombre, de.des_nombre, sub.cantidad
            FROM SERVICIO se
            INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
            INNER JOIN (
            SELECT ca.ser_id, COUNT(ca.ser_id) cantidad
            FROM CARACTERISTICA ca
            INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = ca.ser_id
            WHERE SYSDATE <= di.dis_fecha.fecha_fin
            GROUP BY ca.ser_id
            ORDER BY COUNT(ca.ser_id) DESC
            FETCH FIRST 3 ROWS ONLY)
            sub ON sub.ser_id = se.ser_id)
        LOOP
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' más demandado es '||servicio_mas_demandado.ser_nombre||' en '||servicio_mas_demandado.des_nombre);
            dbms_output.put_line('');
            idali := ali_id_seq.nextVal;
            INSERT INTO ALIANZA VALUES(idali, FECHA(fecha_f,fecha_f + 365*2), EMPTY_BLOB(), ROUND(dbms_random.value(16,30),0));
            idserv := ser_id_seq.nextVal;
            -- Buscar destino menos demandado
            FOR destino_menos_demandado IN
                (SELECT de.des_id, de.des_nombre
                FROM DESTINO_TURISTICO de
                INNER JOIN SERVICIO se
                ON de.des_id = se.des_id
                INNER JOIN (
                SELECT ca.ser_id, COUNT(ca.ser_id)
                FROM CARACTERISTICA ca
                INNER JOIN DISPONIBILIDAD di
                ON di.ser_id = ca.ser_id
                WHERE SYSDATE <= di.dis_fecha.fecha_fin
                GROUP BY ca.ser_id
                ORDER BY COUNT(ca.ser_id) ASC
                FETCH FIRST 1 ROWS ONLY)
                sub ON sub.ser_id = se.ser_id)
            LOOP
                dbms_output.put_line('Se concretó una alianza para suplir el servicio en el destino menos demandado: '||destino_menos_demandado.des_nombre);
                dbms_output.put_line('');
                iddest := destino_menos_demandado.des_id;
                iddest_menosdem := iddest;
            END LOOP;
            INSERT INTO SERVICIO VALUES(idserv, servicio_mas_demandado.ser_nombre, ROUND(dbms_random.value(50,1000),0), ROUND(dbms_random.value(1,250),0), 1, iddest, NULL, idali);
            INSERT INTO DISPONIBILIDAD VALUES(dis_id_seq.nextVal, FECHA(fecha_f,fecha_f + 365*2), fecha_f, ROUND(dbms_random.value(50,1000),0), idserv);
            cont := cont + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
        cont := 1;

        -- 3 Servicios mejores calificados y disponibles actualmente
        FOR servicio_mejor_calificado IN
            (SELECT se.ser_nombre, de.des_nombre, sub.calificacion
            FROM SERVICIO se
            INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
            INNER JOIN (
            SELECT ob.ser_id, AVG(ob.obs_calif) calificacion
            FROM OBSERVACION ob
            INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = ob.ser_id
            WHERE SYSDATE <= di.dis_fecha.fecha_fin
            GROUP BY ob.ser_id
            ORDER BY AVG(ob.obs_calif) DESC
            FETCH FIRST 3 ROWS ONLY)
            sub ON sub.ser_id = se.ser_id)
        LOOP
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' mejor calificado es '||servicio_mejor_calificado.ser_nombre||' en '||servicio_mejor_calificado.des_nombre);
            dbms_output.put_line('');
            idali := ali_id_seq.nextVal;
            INSERT INTO ALIANZA VALUES(idali, FECHA(fecha_f,fecha_f + 365*2), EMPTY_BLOB(), ROUND(dbms_random.value(16,30),0));
            idserv := ser_id_seq.nextVal;
            -- Buscar segundo destino menos demandado
            FOR seg_destino_menos_demandado IN
                (SELECT de.des_id, de.des_nombre
                FROM DESTINO_TURISTICO de
                INNER JOIN SERVICIO se
                ON de.des_id = se.des_id
                INNER JOIN (
                SELECT ca.ser_id, COUNT(ca.ser_id)
                FROM CARACTERISTICA ca
                INNER JOIN DISPONIBILIDAD di
                ON di.ser_id = ca.ser_id
                WHERE SYSDATE <= di.dis_fecha.fecha_fin
                GROUP BY ca.ser_id
                ORDER BY COUNT(ca.ser_id) ASC
                FETCH FIRST 2 ROWS ONLY)
                sub ON sub.ser_id = se.ser_id
                WHERE de.des_id != iddest_menosdem)
            LOOP
                dbms_output.put_line('Se concretó una alianza para suplir el servicio en el segundo destino menos demandado: '||seg_destino_menos_demandado.des_nombre);
                dbms_output.put_line('');
                iddest := seg_destino_menos_demandado.des_id;
            END LOOP;
            INSERT INTO SERVICIO VALUES(idserv, servicio_mejor_calificado.ser_nombre, ROUND(dbms_random.value(50,1000),0), ROUND(dbms_random.value(1,250),0), 1, iddest, NULL, idali);
            INSERT INTO DISPONIBILIDAD VALUES(dis_id_seq.nextVal, FECHA(fecha_f,fecha_f + 365*2), fecha_f, ROUND(dbms_random.value(50,1000),0), idserv);
            cont := cont + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
        cont := 1;

        -- 2 Servicios menos demandados y disponibles actualmente
        FOR servicio_menos_demandado IN
            (SELECT se.ser_id, se.ser_nombre, de.des_nombre, sub.cantidad
            FROM SERVICIO se
            INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
            INNER JOIN (
            SELECT ca.ser_id, COUNT(ca.ser_id) cantidad
            FROM CARACTERISTICA ca
            INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = ca.ser_id
            WHERE SYSDATE <= di.dis_fecha.fecha_fin
            GROUP BY ca.ser_id
            ORDER BY COUNT(ca.ser_id) ASC
            FETCH FIRST 2 ROWS ONLY)
            sub ON sub.ser_id = se.ser_id)
        LOOP
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' menos demandado es '||servicio_menos_demandado.ser_nombre||' en '||servicio_menos_demandado.des_nombre);
            DBMS_OUTPUT.PUT_LINE('');
            UPDATE DISPONIBILIDAD di SET di.dis_fecha.fecha_fin = SYSDATE WHERE di.ser_id = servicio_menos_demandado.ser_id;
            DBMS_OUTPUT.PUT_LINE('Se descontinuó el servicio.');
            DBMS_OUTPUT.PUT_LINE('');
            cont := cont + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
        cont := 1;

        -- 2 Servicios peores calificados y disponibles actualmente
        FOR servicio_peor_calificado IN
            (SELECT se.ser_nombre, de.des_nombre, sub.calificacion, se.SER_ID
            FROM SERVICIO se
            INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
            INNER JOIN (
            SELECT ob.ser_id, AVG(ob.obs_calif) calificacion
            FROM OBSERVACION ob
            INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = ob.ser_id
            WHERE SYSDATE <= di.dis_fecha.fecha_fin
            GROUP BY ob.ser_id
            ORDER BY AVG(ob.obs_calif) ASC
            FETCH FIRST 2 ROWS ONLY)
            sub ON sub.ser_id = se.ser_id)
        LOOP
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' peor calificado es'||servicio_peor_calificado.ser_nombre||' en '||servicio_peor_calificado.des_nombre);
            DBMS_OUTPUT.PUT_LINE('');
            UPDATE DISPONIBILIDAD di SET di.dis_fecha.fecha_fin = SYSDATE WHERE di.ser_id = servicio_peor_calificado.ser_id;
            DBMS_OUTPUT.PUT_LINE('Se descontinuó el servicio.');
            DBMS_OUTPUT.PUT_LINE('');
            cont := cont + 1;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
        cont := 1;

        -- 2 Servicios con las peores relaciones ingreso vs egreso y disponibles actualmente
        FOR servicio_peor_ganancia IN
            (SELECT se.ser_nombre, se.SER_ID, de.des_nombre, sub.ganancia - se.ser_costo_mensual * ROUND(MONTHS_BETWEEN(fecha_ini,fecha_f),0) relacionpc
            FROM SERVICIO se
            INNER JOIN DESTINO_TURISTICO de
            ON de.des_id = se.des_id
            INNER JOIN (
            SELECT ca.ser_id, SUM(se.ser_precio_unitario) ganancia
            FROM SERVICIO se
            INNER JOIN DISPONIBILIDAD di
            ON di.ser_id = se.ser_id
            INNER JOIN CARACTERISTICA ca
            ON ca.ser_id = se.ser_id
            WHERE (SYSDATE <= di.dis_fecha.fecha_fin) AND (fecha_ini <= ca.car_fecha.fecha_inicio) AND (fecha_f >= ca.car_fecha.fecha_fin)
            GROUP BY ca.ser_id)
            sub ON sub.ser_id = se.ser_id
            ORDER BY relacionpc ASC
            FETCH FIRST 2 ROWS ONLY)
        LOOP
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' de peor relacion ganancia-costo es '||servicio_peor_ganancia.ser_nombre||' en '||servicio_peor_ganancia.des_nombre);
            DBMS_OUTPUT.PUT_LINE('');
            UPDATE DISPONIBILIDAD di SET di.dis_fecha.fecha_fin = SYSDATE WHERE di.ser_id = servicio_peor_ganancia.ser_id;
            DBMS_OUTPUT.PUT_LINE('Se descontinuó el servicio.');
            DBMS_OUTPUT.PUT_LINE('');
            cont := cont + 1;
        END LOOP;

        UPDATE DISPONIBILIDAD di SET di.dis_fecha.fecha_fin = (dis_fecha.fecha_fin + 365) WHERE di.dis_fecha.fecha_fin > SYSDATE;
        DBMS_OUTPUT.PUT_LINE('Se renovaron las disponibilidades de todos los demás servicios por 1 año.');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Fin de la simulación.');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------'); 
    END;
END;