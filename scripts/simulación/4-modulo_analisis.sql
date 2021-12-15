-- Modulo de Análisis 
CREATE OR REPLACE PACKAGE MODULO_ANALISIS IS
    PROCEDURE analisis_servicios();
END;

/

CREATE OR REPLACE PACKAGE BODY MODULO_ANALISIS AS
    PROCEDURE analisis_servicios(fecha_ini DATE, fecha_f DATE)
    IS
        cont NUMBER; 
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
            cont := cont + 1; 
        END LOOP; 
        
        DBMS_OUTPUT.PUT_LINE(''); 
        cont := 1;     
        
        -- 3 Servicios menos demandados y disponibles actualmente 
        FOR servicio_menos_demandado IN  
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
            ORDER BY COUNT(ca.ser_id) ASC 
            FETCH FIRST 3 ROWS ONLY) 
            sub ON sub.ser_id = se.ser_id)  
        LOOP 
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' menos demandado es '||servicio_menos_demandado.ser_nombre||' en '||servicio_menos_demandado.des_nombre); 
            cont := cont + 1; 
        END LOOP; 
        
        DBMS_OUTPUT.PUT_LINE(''); 
        cont := 1;  
        
        -- 3 Servicios peores calificados y disponibles actualmente 
        FOR servicio_peor_calificado IN  
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
            ORDER BY AVG(ob.obs_calif) ASC 
            FETCH FIRST 3 ROWS ONLY) 
            sub ON sub.ser_id = se.ser_id)  
        LOOP 
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' peor calificado es'||servicio_peor_calificado.ser_nombre||' en '||servicio_peor_calificado.des_nombre); 
            cont := cont + 1; 
        END LOOP; 

        DBMS_OUTPUT.PUT_LINE(''); 
        cont := 1;  
        
        -- 3 Servicios con las peores relaciones ingreso vs egreso y disponibles actualmente 
        FOR servicio_peor_ganancia IN  
            (SELECT se.ser_nombre, de.des_nombre, (sub.ganancia - se.ser_costo_mensual * ROUND(MONTHS_BETWEEN(fecha_ini,fecha_f)),0) relacionpc 
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
            ORDER BY relacionpc ASC) 
        LOOP 
            DBMS_OUTPUT.PUT_LINE('El servicio número '||cont||' de peor relacion ganancia-costo es '||servicio_peor_ganancia.ser_nombre||' en '||servicio_peor_ganancia.des_nombre); 
            cont := cont + 1; 
        END LOOP;
    END;
END;