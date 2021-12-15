CREATE  OR REPLACE PACKAGE MODULO_VIAJE IS
    FUNCTION GENERAR_PCR(cliente_id NUMBER, fecha_PCR DATE) RETURN NUMBER;
    PROCEDURE INICIO_VIAJE(primer_paquete NUMBER);
    PROCEDURE VIAJE(primer_paquete NUMBER);


END;
/


CREATE OR REPLACE PACKAGE BODY MODULO_VIAJE AS

    /* FUNCION PARA GENERAR LOS PCR */
    FUNCTION GENERAR_PCR(cliente_id NUMBER, fecha_PCR DATE) RETURN NUMBER
    IS
        resultado_pcr NUMBER := ROUND(DBMS_RANDOM.VALUE(0,1));
    BEGIN
        IF(resultado_pcr = 1) THEN
            INSERT INTO PCR VALUES(PCR_ID_SEQ.nextval, fecha_PCR, resultado_pcr, cliente_id);
        ELSE
            INSERT INTO PCR VALUES(PCR_ID_SEQ.nextval, fecha_PCR, resultado_pcr, cliente_id);
        end if;
        RETURN resultado_pcr;
    END;


    /* AQUI SE LLEVAN A CABO LAS VERIFICACIONES Y ASISTENCIAS AL VIAJE */
    PROCEDURE VIAJE(primer_paquete NUMBER)
    IS
        fecha_pcr DATE;
        resultado_pcr NUMBER;
        destin DESTINO_TURISTICO%rowtype;
        client CLIENTE%rowtype;
    BEGIN
        FOR paquete_vendido IN (SELECT paq.PAQ_ID as paquete, paq.DES_ID as destino, paq.PAQ_FECHA as fechas, cli.CLI_ID as comprador FROM PAQUETE_TURISTICO paq
            INNER JOIN PERTENENCIA pert ON paq.PAQ_ID = pert.PAQ_ID
            INNER JOIN CLIENTE cli on cli.CLI_ID = pert.CLI_ID
            WHERE paq.PAQ_ID >= primer_paquete) LOOP

                SELECT * INTO destin FROM DESTINO_TURISTICO WHERE DES_ID = paquete_vendido.destino;
                SELECT * INTO client FROM CLIENTE WHERE CLI_ID = paquete_vendido.comprador;

                IF(client.CLI_DATOS.DAT_VACUNADO = 1) THEN
                    DBMS_OUTPUT.PUT_LINE('El cliente '||client.CLI_DATOS.DAT_PRIMER_NOMBRE||' '||client.CLI_DATOS.DAT_PRIMER_APELLIDO||' está vacunado, por lo cual puede asistir sin problemas a '||destin.DES_NOMBRE||' el '||paquete_vendido.fechas.FECHA_INICIO);
                ELSE
                    fecha_pcr := paquete_vendido.fechas.FECHA_INICIO - 3;
                    resultado_pcr := GENERAR_PCR(client.CLI_ID, fecha_pcr);

                    IF(resultado_pcr = 1) THEN
                        DBMS_OUTPUT.PUT_LINE('El cliente '||client.CLI_DATOS.DAT_PRIMER_NOMBRE||' '||client.CLI_DATOS.DAT_PRIMER_APELLIDO||' se hizo la prueba PCR el '||fecha_pcr||' dando (+), y en 3 días viaja, por lo cual deberá tomar todas las precauciones posibles');
                    ELSE
                        DBMS_OUTPUT.PUT_LINE('El cliente '||client.CLI_DATOS.DAT_PRIMER_NOMBRE||' '||client.CLI_DATOS.DAT_PRIMER_APELLIDO||' se hizo la prueba PCR el '||fecha_pcr||' dando (-), por lo cual puede asistir sin problemas a '||destin.DES_NOMBRE||' el '||paquete_vendido.fechas.FECHA_INICIO);
                    end if;
                end if;
        end loop;

         FOR paquete_vendido2 IN (SELECT paq.PAQ_ID as paquete, paq.DES_ID as destino, paq.PAQ_FECHA as fechas, cli.CLI_ID as comprador, serv.SER_ID as servic FROM PAQUETE_TURISTICO paq
            INNER JOIN PERTENENCIA pert ON paq.PAQ_ID = pert.PAQ_ID
            INNER JOIN CLIENTE cli on cli.CLI_ID = pert.CLI_ID
            INNER JOIN CARACTERISTICA car on paq.PAQ_ID = car.PAQ_ID
            INNER JOIN SERVICIO serv on car.SER_ID = serv.SER_ID
            WHERE paq.PAQ_ID >= primer_paquete) LOOP

             INSERT INTO ASISTENCIA VALUES(ASI_ID_SEQ.nextval, 1, paquete_vendido2.fechas.FECHA_INICIO,paquete_vendido2.comprador, paquete_vendido2.servic);
        end loop;

            dbms_output.put_line(' ');
            DBMS_OUTPUT.PUT_LINE('LOS CLIENTES HAN ASISTIDO A SUS RESPECTIVOS VIAJES :)');
            dbms_output.put_line(' ');
    END;



    /* INICIO DEL VIAJE, EN DONDE SE VERIFCA SI ESTÁN VACUNADOS, O SI NO TIENEN COVID PARA QUE PUEDAN ASISTIR */
    PROCEDURE  INICIO_VIAJE(primer_paquete NUMBER)
    IS

    BEGIN
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');
        dbms_output.put_line('******************************');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('*  REALIZANDO PREVENCIONES   *');
        dbms_output.put_line('*       ANTI COVID-19        *');
        dbms_output.put_line('*                            *');
        dbms_output.put_line('******************************');
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');
        dbms_output.put_line(' 3 días antes de cada viaje se pedirán certificados de vacunación, o en su defecto, pruebas PCR');
        dbms_output.put_line(' ');
        dbms_output.put_line(' ');

        VIAJE(primer_paquete);
    END;

END;