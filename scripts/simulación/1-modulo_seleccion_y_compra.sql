CREATE OR REPLACE PACKAGE MODULO_SELECCION_COMPRA IS
    PROCEDURE inicio_simulacion(fecha_inicio DATE DEFAULT SYSDATE, num_clientes NUMBER);
    PROCEDURE seleccion_clientes(cli CLIENTE%rowtype, primer_paquete IN OUT NUMBER, fecha_simulacion DATE);
    PROCEDURE comprar_paquete_solo(cli CLIENTE%rowtype, primer_paquete IN OUT NUMBER, fecha_simulacion DATE);
END;
/

CREATE OR REPLACE PACKAGE BODY MODULO_SELECCION_COMPRA AS

    /* PROCEDURE PARA SELECCIONAR QUIÉNES SERÁN LOS CLIENTES COMPRADORES*/
    PROCEDURE seleccion_clientes(cli CLIENTE%rowtype, primer_paquete IN OUT NUMBER, fecha_simulacion DATE)
        IS
            meses_vividos NUMBER := 0;
            fam1 FAMILIAR%rowtype;
            fam2 FAMILIAR%rowtype;
        BEGIN
            SELECT MONTHS_BETWEEN(sysdate, cli.CLI_DATOS.DAT_FECHA_NACIMIENTO) INTO meses_vividos FROM dual;
            IF(meses_vividos >= 216)THEN
                comprar_paquete_solo(cli, primer_paquete, fecha_simulacion);
            end if;

        END;

/* PROCEDIMIENTO PARA QUE EL USUARIO SOLITARIO, COMPRE SUS PAQUETES */
    PROCEDURE comprar_paquete_solo(cli CLIENTE%rowtype, primer_paquete IN OUT NUMBER,fecha_simulacion DATE)
    IS
        flag NUMBER := 1;
        flag_servicio NUMBER :=1;
        fecha_inicio DATE;
        fecha_fin DATE;
        dias_viaje NUMBER := round(DBMS_RANDOM.VALUE(1,30));
        dias_antes_viaje NUMBER;
        paquetes_a_comprar NUMBER := 1;
        destino_aleatorio DESTINO_TURISTICO%rowtype;
        es_disponible NUMBER := 1;
        monto_total NUMBER := 0;
        medios_pago NUMBER := round(DBMS_RANDOM.VALUE (1, 3));
        monto_medio_pago NUMBER;
        tipo_medio_pago VARCHAR2(40);
        canal_pago NUMBER := round(DBMS_RANDOM.VALUE(1,4));
        disp_canal_pago VARCHAR2(40);
        tipo_canal_pago VARCHAR2(40);
        id_pago NUMBER;
        id_paquete NUMBER;
        TYPE lista_servicio is VARRAY(3) OF SERVICIO%ROWTYPE;
        lista_servicios lista_servicio := lista_servicio();
        contador_servicios NUMBER := 0;
        solo_servicio SERVICIO%rowtype;
        monto_abonado NUMBER := 0;
        limite_destinos NUMBER;
    BEGIN
        FOR i IN 1..paquetes_a_comprar LOOP
            flag := 1;
            SELECT * INTO destino_aleatorio FROM DESTINO_TURISTICO ORDER BY DBMS_RANDOM.RANDOM ASC FETCH FIRST 1 ROWS ONLY;
            WHILE flag = 1 LOOP
                es_disponible := 1;
                dias_antes_viaje  := round(DBMS_RANDOM.VALUE(25,60));
                paquetes_a_comprar := round(DBMS_RANDOM.VALUE (1, 3));
                dias_viaje  := round(DBMS_RANDOM.VALUE(61,90));
                fecha_inicio := fecha_simulacion + dias_antes_viaje;
                fecha_fin := fecha_simulacion + dias_viaje;

                FOR paquetes_comprados IN (SELECT * FROM PAQUETE_TURISTICO paq INNER JOIN PERTENENCIA per on paq.PAQ_ID = per.PAQ_ID WHERE cli.CLI_ID = per.CLI_ID) LOOP
                    IF( ((TO_DATE(fecha_inicio, 'DD-MM-YYYY') > TO_DATE(paquetes_comprados.PAQ_FECHA.FECHA_INICIO, 'DD-MM-YYYY')) AND (TO_DATE(fecha_inicio, 'DD-MM-YYYY') < TO_DATE(paquetes_comprados.PAQ_FECHA.FECHA_FIN, 'DD-MM-YYYY')) ) OR ((TO_DATE(fecha_fin, 'DD-MM-YYYY') > TO_DATE(paquetes_comprados.PAQ_FECHA.FECHA_INICIO, 'DD-MM-YYYY')) AND (TO_DATE(fecha_fin, 'DD-MM-YYYY') < TO_DATE(paquetes_comprados.PAQ_FECHA.FECHA_FIN, 'DD-MM-YYYY'))) ) THEN
                        es_disponible := 0;
                        EXIT;
                    end if;
                end loop;

                IF(es_disponible = 1) THEN

                    flag_servicio := 1;
                    limite_destinos := 3;

                WHILE(flag_servicio = 1) LOOP

                    /* GENERAR SERVICIOS ALETORIOS*/
                    FOR servicio_seleccionado IN (SELECT ser.SER_ID FROM SERVICIO ser
                        INNER JOIN DESTINO_TURISTICO dest on dest.DES_ID = ser.DES_ID
                        INNER JOIN DISPONIBILIDAD dis ON ser.SER_ID = dis.SER_ID
                        WHERE ((dis.DIS_CANTIDAD_DISP > 0) AND (TO_DATE(fecha_inicio,'DD-MM-YYYY') >= TO_DATE(dis.DIS_FECHA.FECHA_INICIO, 'DD-MM-YYYY')) AND (TO_DATE(fecha_fin, 'DD-MM-YYYY') <= TO_DATE(dis.DIS_FECHA.FECHA_FIN, 'DD-MM-YYYY')) AND (dest.DES_ID = destino_aleatorio.DES_ID))
                        ORDER BY DBMS_RANDOM.RANDOM ASC FETCH FIRST 3 ROWS ONLY) LOOP

                            SELECT * INTO solo_servicio FROM SERVICIO servi WHERE servi.SER_ID = servicio_seleccionado.SER_ID;

                            DBMS_OUTPUT.PUT_LINE('El cliente '||cli.CLI_DATOS.DAT_PRIMER_NOMBRE||' '||cli.CLI_DATOS.DAT_PRIMER_APELLIDO||' ha adquirido el servicio '||solo_servicio.SER_NOMBRE||' en '||destino_aleatorio.DES_NOMBRE||' por $'||round(solo_servicio.SER_PRECIO_UNITARIO));
                            monto_total := monto_total + solo_servicio.SER_PRECIO_UNITARIO;
                            contador_servicios := contador_servicios + 1;
                            lista_servicios.extend();
                            lista_servicios(contador_servicios) := solo_servicio;
                            limite_destinos := 1;
                    end loop;

                    IF((solo_servicio.SER_ID IS NULL) AND (limite_destinos != 0)) THEN
                        SELECT * INTO destino_aleatorio FROM DESTINO_TURISTICO ORDER BY DBMS_RANDOM.RANDOM ASC FETCH FIRST 1 ROWS ONLY;
                        limite_destinos := limite_destinos - 1;
                    ELSE
                        flag_servicio := 0;
                    end if;

                end loop;

                    IF(limite_destinos != 0) THEN
                        DBMS_OUTPUT.PUT_LINE('El monto total a pagar es de: $'||monto_total);
                        DBMS_OUTPUT.PUT_LINE(' ');
                    end if;

CASE canal_pago
                    WHEN 1 THEN
                        tipo_canal_pago := 'Web';
                        disp_canal_pago := 'Dell';
                    WHEN 2 THEN
                        tipo_canal_pago := 'Web';
                        disp_canal_pago := 'HP';
                    WHEN 3 THEN
                        tipo_canal_pago := 'App';
                        disp_canal_pago := 'Android';
                    WHEN 4 THEN
                        tipo_canal_pago := 'App';
                        disp_canal_pago := 'iOS';
                    END CASE;

                    IF(limite_destinos != 0) THEN
                        DBMS_OUTPUT.PUT_LINE('La compra se hizo desde un dispositivo '||disp_canal_pago||' por '||tipo_canal_pago);
                        DBMS_OUTPUT.PUT_LINE('Con unos abonos de:');
                        DBMS_OUTPUT.PUT_LINE(' ');
                    end if;


                    INSERT INTO PAGO VALUES (PAG_ID_SEQ.nextVal, tipo_canal_pago, disp_canal_pago, fecha_simulacion, monto_total, cli.CLI_ID) RETURNING PAG_ID INTO id_pago;

                    /* AHORA GENERAR MEDIOS DE  PAGOS ALEATORIOS*/
                    FOR i IN 1..medios_pago LOOP

                        IF((i = medios_pago) OR (i = 3)) THEN
                            monto_medio_pago := monto_total - monto_abonado;
                        ELSE
                            monto_medio_pago := (round(DBMS_RANDOM.VALUE (1, monto_total))/2);
                            monto_abonado := monto_abonado + monto_medio_pago;
                        end if;

                        CASE i
                        WHEN 1 THEN
                            tipo_medio_pago := 'TDC';
                        WHEN 2 THEN
                            tipo_medio_pago := 'Cripto';
                        WHEN 3 THEN
                            tipo_medio_pago := 'Efectivo';
                        END CASE;

                        INSERT INTO MEDIO_PAGO VALUES(MED_ID_SEQ.nextval, tipo_medio_pago, monto_medio_pago, id_pago);

                        IF(limite_destinos != 0) THEN
                            DBMS_OUTPUT.PUT_LINE(tipo_medio_pago||': $'||monto_medio_pago);
                        end if;


                        IF(monto_total = 0) THEN
                            EXIT;
                        end if;
                    end loop;

                    INSERT INTO PAQUETE_TURISTICO VALUES (PAQ_ID_SEQ.nextval, PRECIO(monto_total), FECHA(fecha_inicio, fecha_fin), id_pago, destino_aleatorio.DES_ID) RETURNING PAG_ID INTO id_paquete;
                    IF(primer_paquete = 0)THEN
                        primer_paquete := id_paquete;
                    end if;
                    INSERT INTO PERTENENCIA VALUES(cli.CLI_ID, id_paquete);

                    FOR i IN 1..contador_servicios LOOP
                        INSERT INTO CARACTERISTICA VALUES (id_paquete, lista_servicios(i).SER_ID, FECHA(fecha_fin,fecha_fin));
                        UPDATE DISPONIBILIDAD disp SET disp.DIS_CANTIDAD_DISP = disp.DIS_CANTIDAD_DISP - 1 WHERE disp.SER_ID = lista_servicios(i).SER_ID;
                    end loop;


                    IF(limite_destinos != 0)THEN
                        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');
                        DBMS_OUTPUT.PUT_LINE(' ');
                    end if;

                    flag := 0;
                    monto_total := 0;
                    contador_servicios := 0;
                end if;

            end loop;

        end loop;

    END;


        /* PROCEDURE PARA INICIAR LA SIMULACIÓN Y SOLICITARLE QUE INDIQUE EL NÚMERO DE CLIENTES QUE COMPRARÁN */

PROCEDURE  inicio_simulacion(fecha_inicio DATE DEFAULT SYSDATE, num_clientes NUMBER)
        IS
            fecha_fin DATE;
            primer_paquete NUMBER := 0;
            costomant NUMBER;
            conceptomant VARCHAR(40);
            fechamant DATE;
        BEGIN
            fecha_fin := ADD_MONTHS(fecha_inicio,4);
            DBMS_OUTPUT.PUT_LINE('*****************************************************');
            DBMS_OUTPUT.PUT_LINE('*                                                   *');
            DBMS_OUTPUT.PUT_LINE('* BIENVENIDO A LA SIMULACIÓN DE ESTRELLA CARIBEÑA   *');
            DBMS_OUTPUT.PUT_LINE('*                                                   *');
            DBMS_OUTPUT.PUT_LINE('* Esta simulación tendrá como fechas:               *');
            DBMS_OUTPUT.PUT_LINE('* Desde:' ||fecha_inicio||'                                    *');
            DBMS_OUTPUT.PUT_LINE('* Hasta:' ||fecha_fin|| '                                    *');
            DBMS_OUTPUT.PUT_LINE('*                                                   *');
            DBMS_OUTPUT.PUT_LINE('*Con un total de '||num_clientes||' clientes.                       *');
            DBMS_OUTPUT.PUT_LINE('*                                                   *');
            DBMS_OUTPUT.PUT_LINE('*****************************************************');

            DBMS_OUTPUT.PUT_LINE('       ');
            DBMS_OUTPUT.PUT_LINE('Seleccionando clientes...');
            DBMS_OUTPUT.PUT_LINE('Los clientes han sido seleccionados, y ahora procederán a comprar sus paquetes: ');
            DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------');
            dbms_output.put_line(' ');
            dbms_output.put_line(' ');
            dbms_output.put_line('******************************');
            dbms_output.put_line('*                            *');
            dbms_output.put_line('*     COMPRANDO PAQUETES     *');
            dbms_output.put_line('*                            *');
            dbms_output.put_line('******************************');
            dbms_output.put_line(' ');
            dbms_output.put_line(' ');

            FOR cliente_aleatorio IN (SELECT * FROM CLIENTE ORDER BY DBMS_RANDOM.RANDOM ASC FETCH FIRST num_clientes ROWS ONLY) LOOP
                seleccion_clientes(cliente_aleatorio, primer_paquete, fecha_inicio);
            END LOOP;

            /* LLAMAMOS AL MODULO DE VIAJE Y OBSERVACION */
            MODULO_VIAJE.INICIO_VIAJE(primer_paquete);
            MODULO_OBSERVACION.INICIO_OBSERVACION(primer_paquete);
            MODULO_ANALISIS.analisis_servicios(fecha_inicio,fecha_fin);

            FOR barco IN 
            (SELECT cr.tra_id, tr.tra_nombre, cr.cru_mant.fecha_prox_mant AS fmant 
            FROM CRUCERO cr 
            INNER JOIN TRANSPORTE tr 
            ON tr.tra_id = cr.tra_id 
            WHERE cr.cru_mant.fecha_prox_mant <= '14-ABR-2022') 
            LOOP 
                costomant := ROUND(dbms_random.value(50,15000),0); 
                fechamant := barco.fmant; 
                IF(costomant <= 500) THEN 
                    conceptomant := 'Revisión General'; 
                ELSIF (costomant <= 12500) THEN 
                    conceptomant := 'Reparación Parcial'; 
                ELSE 
                    conceptomant := 'Reparación Total'; 
                END IF; 
                INSERT INTO MANTENIMIENTO VALUES (man_id_seq.nextVal, fechamant, conceptomant, costomant, barco.tra_id); 
                dbms_output.put_line('Se le hizo mantenimiento al crucero '||barco.tra_nombre||' el día '||fechamant||' por concepto de '||conceptomant||' con un costo de $ '||costomant); 
                fechamant := TDA_MANTENIMIENTO.fechaProxMant(fechamant,ROUND(dbms_random.value(1,4),0)); 
                UPDATE CRUCERO cr SET cr.cru_mant.fecha_prox_mant = fechamant; 
                dbms_output.put_line('Su próximo mantenimiento será el '||fechamant); 
                dbms_output.put_line(''); 
            END LOOP; 
            dbms_output.put_line('');
            DBMS_OUTPUT.PUT_LINE('Fin de la simulación');
            DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------');
        END;

END;