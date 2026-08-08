-- ===========================================================================
-- V202608081030__add_columnas_fidelidad_y_notas.sql
--
-- COLUMNA AÑADIDA A TABLA EXISTENTE. Dos solicitudes independientes del dueño
-- del taller, empaquetadas en una sola migración porque ambas son ALTER TABLE
-- de bajo riesgo y no ameritan dos despliegues separados:
--   1. Marketing quiere segmentar clientes frecuentes para dar descuentos.
--   2. El mostrador necesita un campo libre para anotar detalles de la orden
--      que no encajan en ningún otro campo ("cliente pidió que quede lista
--      antes del viernes", "traer sin pedal izquierdo").
-- ===========================================================================

ALTER TABLE clientes
    ADD COLUMN nivel_fidelidad VARCHAR(20) NOT NULL DEFAULT 'nuevo';

COMMENT ON COLUMN clientes.nivel_fidelidad IS
    'Segmento de fidelidad del cliente: nuevo, frecuente, vip. Calculado manualmente por ahora.';

ALTER TABLE ordenes_servicio
    ADD COLUMN notas TEXT;

COMMENT ON COLUMN ordenes_servicio.notas IS
    'Observaciones libres de recepción o del técnico sobre la orden. NULL si no hay ninguna.';
