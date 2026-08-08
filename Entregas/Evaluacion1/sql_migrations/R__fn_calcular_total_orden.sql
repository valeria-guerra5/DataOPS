-- ===========================================================================
-- R__fn_calcular_total_orden.sql
--
-- Calcula el total de una orden de servicio sumando su detalle de servicios y
-- sus repuestos consumidos. Es lógica de negocio pura: no toca datos ni
-- estructura, así que va como repetible (R__) y no como versionada (V__),
-- siguiendo el mismo criterio que fn_calculate_discount de la Sesión 2.
-- ===========================================================================

CREATE OR REPLACE FUNCTION fn_calcular_total_orden(p_orden_id INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_total_servicios  NUMERIC(12, 2);
    v_total_repuestos  NUMERIC(12, 2);
BEGIN
    IF p_orden_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(SUM(cantidad * precio_aplicado), 0)
    INTO v_total_servicios
    FROM orden_servicio_detalle
    WHERE orden_id = p_orden_id;

    SELECT COALESCE(SUM(cantidad * precio_aplicado), 0)
    INTO v_total_repuestos
    FROM orden_repuestos
    WHERE orden_id = p_orden_id;

    RETURN v_total_servicios + v_total_repuestos;
END;
$$;

-- ¿Por qué STABLE y no IMMUTABLE? A diferencia de fn_calculate_discount (que
-- solo depende de su argumento), esta función consulta tablas: para el mismo
-- orden_id el resultado puede cambiar si alguien agrega una línea de detalle.
-- STABLE le dice al planificador "no cambia dentro de la misma sentencia",
-- que es la promesa correcta para una función que lee de la base.

COMMENT ON FUNCTION fn_calcular_total_orden(INTEGER) IS
    'Total de una orden de servicio = suma de servicios aplicados + suma de repuestos consumidos.';

-- Procedimiento auxiliar: recalcula y persiste el total en ordenes_servicio.total.
-- Se agrupa en el mismo archivo repetible porque ambos objetos cambian juntos
-- (si cambia la fórmula del cálculo, el procedure debe reflejarlo también).
CREATE OR REPLACE PROCEDURE sp_actualizar_total_orden(p_orden_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ordenes_servicio
    SET total = fn_calcular_total_orden(p_orden_id)
    WHERE orden_id = p_orden_id;
END;
$$;

COMMENT ON PROCEDURE sp_actualizar_total_orden(INTEGER) IS
    'Recalcula ordenes_servicio.total a partir del detalle vigente y lo persiste.';
