-- Comprobar que no haya familiar (y, x) si ya hay familiar (x, y): --
CREATE OR REPLACE TRIGGER check_familiares_recursivos 
BEFORE INSERT ON FAMILIAR FOR EACH ROW
    DECLARE
        fam FAMILIAR%ROWTYPE;
    BEGIN
        SELECT *
        INTO fam
        FROM FAMILIAR
        WHERE (:new.cli_id1 = cli_id2 AND :new.cli_id2 = cli_id1);
        RAISE_APPLICATION_ERROR(-20013,'Error. Ya estan registrados como familiares');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN;
    END;

/

-- Comprobar que la cantidad de dias dentro del rango de fechas de disponibilidad sea mayor o igual a ser_duracion:
CREATE OR REPLACE TRIGGER fecha_disponibilidad 
BEFORE INSERT ON DISPONIBILIDAD FOR EACH ROW
    DECLARE
        cantidad_dias NUMBER;
    BEGIN
        SELECT ser_duracion
        INTO cantidad_dias
        FROM SERVICIO
        WHERE (:new.ser_id = ser_id);
        IF(FECHA.cantidadDeDias(:new.dis_fecha.fecha_inicio, :new.dis_fecha.fecha_fin) < cantidad_dias) THEN
            RAISE_APPLICATION_ERROR(-20014,'Error. La cantidad de dias disponibles deben ser mayores o iguales a la cantidad de dias que puede tener el servicio (ser_duracion)');
        END IF;
    END;
    
/

-- Comprobar que la cantidad de dias de caracteristica dentro del rango de fechas sea igual a ser_duracion, y ademas este dentro del rango de fechas del paquete al que esta relacionado y el rango de fechas de la disponibilidad el servicio
CREATE OR REPLACE TRIGGER fecha_caracteristica 
BEFORE INSERT ON CARACTERISTICA FOR EACH ROW
    DECLARE
        cantidad_dias_ser NUMBER;
        fecha_paq FECHA;
        fecha_dis FECHA;
    BEGIN
        SELECT ser_duracion
        INTO cantidad_dias_ser
        FROM SERVICIO
        WHERE (:new.ser_id = ser_id);
        IF(FECHA.cantidadDeDias(:new.car_fecha.fecha_inicio, :new.car_fecha.fecha_fin) != cantidad_dias_ser) THEN
            RAISE_APPLICATION_ERROR(-20015,'Error. La cantidad de dias para disfrutar el servicio de la caracteristica debe ser igual a la cantidad de dias que tiene el servicio (ser_duracion)');
        ELSE
            SELECT paq_fecha
            INTO fecha_paq
            FROM PAQUETE_TURISTICO
            WHERE (:new.paq_id = paq_id);
            IF((fecha_paq.fecha_inicio > :new.car_fecha.fecha_inicio) OR (fecha_paq.fecha_fin < :new.car_fecha.fecha_fin)) THEN
                RAISE_APPLICATION_ERROR(-20016,'Error. El rango de fechas de la caracteristica debe estar dentro del rango de fecha del paquete');
            ELSE
                SELECT dis_fecha
                INTO fecha_dis
                FROM DISPONIBILIDAD
                WHERE (:new.ser_id = ser_id);
                IF((fecha_dis.fecha_inicio > :new.car_fecha.fecha_inicio) OR (fecha_dis.fecha_fin < :new.car_fecha.fecha_fin)) THEN
                    RAISE_APPLICATION_ERROR(-20017,'Error. El rango de fechas de la caracteristica debe estar dentro del rango de fecha de la disponibilidad del servicio');
                END IF;
            END IF;
        END IF;
    END;
    
/

CREATE OR REPLACE TRIGGER sc_sumar_precio
AFTER INSERT ON CARACTERISTICA FOR EACH ROW
    DECLARE
        obprecio PRECIO;
        valpr NUMBER;
    BEGIN
        SELECT paq_precio
        INTO obprecio
        FROM PAQUETE_TURISTICO
        WHERE (:new.paq_id = paq_id);
        
        SELECT ser_precio_unitario
        INTO valpr
        FROM SERVICIO
        WHERE (:new.ser_id = ser_id);
        
        obprecio.sumarPrecio(valpr);
    END;
