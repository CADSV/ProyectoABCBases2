CREATE OR REPLACE PACKAGE MODULO_OBSERVACION IS
    PROCEDURE INICIO_OBSERVACION(primer_paquete NUMBER);
    PROCEDURE OBSERVACION(primer_paquete NUMBER);

END;
/

CREATE OR REPLACE PACKAGE BODY MODULO_OBSERVACION AS

    /*OBSERVACION COMO TAL */
    PROCEDURE OBSERVACION(primer_paquete NUMBER)
    IS
        calificacion NUMBER;
        texto VARCHAR2(40);
        destin DESTINO_TURISTICO%rowtype;
        client CLIENTE%rowtype;
        service SERVICIO%rowtype;
    BEGIN
        FOR paquete_vendido IN (SELECT paq.PAQ_ID as paquete, paq.DES_ID as destino, paq.PAQ_FECHA as fechas, cli.CLI_ID as comprador, serv.SER_ID as servic FROM PAQUETE_TURISTICO paq
            INNER JOIN PERTENENCIA pert ON paq.PAQ_ID = pert.PAQ_ID
            INNER JOIN CLIENTE cli on cli.CLI_ID = pert.CLI_ID
            INNER JOIN CARACTERISTICA car on paq.PAQ_ID = car.PAQ_ID
            INNER JOIN SERVICIO serv on car.SER_ID = serv.SER_ID
            WHERE paq.PAQ_ID >= primer_paquete) LOOP

            select trunc(dbms_random.value(0.0, 3.0),1) into calificacion from dual;

            IF((calificacion <=3) AND (calificacion >= 2.5)) THEN
                texto := '"Excelente servicio"';
            end if;
            IF((calificacion <2.5) AND (calificacion > 1.5)) THEN
                texto := '"Estuvo bueno"';
            end if;
            IF((calificacion <=1.5) AND (calificacion >= 0)) THEN
                texto := '"No me gustó nada"';
            end if;

            INSERT INTO OBSERVACION VALUES(OBS_ID_SEQ.nextval, calificacion, texto, paquete_vendido.fechas.FECHA_FIN, paquete_vendido.servic, paquete_vendido.comprador);

            SELECT * INTO destin FROM DESTINO_TURISTICO WHERE DES_ID = paquete_vendido.destino;
            SELECT * INTO client FROM CLIENTE WHERE CLI_ID = paquete_vendido.comprador;
            SELECT * INTO service FROM SERVICIO WHERE SER_ID = paquete_vendido.servic;

            DBMS_OUTPUT.PUT_LINE('El cliente '||client.CLI_DATOS.DAT_PRIMER_NOMBRE||' '||client.CLI_DATOS.DAT_PRIMER_APELLIDO||' calificó el servicio de '||service.SER_NOMBRE||' en '||destin.DES_NOMBRE||' como '||texto||', tras una calificación de '||calificacion||' pts.');

        end loop;

    END;


    /*INICIO DE LA OBSERVACION*/
    PROCEDURE INICIO_OBSERVACION(primer_paquete NUMBER)
    IS

    BEGIN
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');
        DBMS_OUTPUT.PUT_LINE('TODOS LOS CLIENTES QUE VIAJARON HAN VUELTO DE SUS VACACIONES');
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');
        dbms_output.put_line('******************************');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('*          MÓDULO DE         *');
        dbms_output.put_line('*        OBERVACIONES        *');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('******************************');
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');
        dbms_output.put_line('Justo al volver de sus experiencias vividas de la mano de Estrella Caribeña y sus aliados, los clientes califican y observarán cada uno de los servicios:');
        DBMS_OUTPUT.PUT_LINE('Todas las calificaciones realizadas serán en una escala del 0 al 3. ');
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');

        OBSERVACION(primer_paquete);
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('Estrella Caribeña está sumamente agradecido con sus clientes, por la oportunidad, el disfrute y las recomendaciones. !Nos vemos pronto!');
    END;


END;