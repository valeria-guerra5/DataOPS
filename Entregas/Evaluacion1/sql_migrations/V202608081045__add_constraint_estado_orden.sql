-- ===========================================================================
-- V202608081045__add_constraint_estado_orden.sql
--
-- RESTRICCIÓN. Hasta ahora `ordenes_servicio.estado` era un VARCHAR libre: ya
-- aparecieron 'recibida', 'en_proceso', 'entregada' escritos de formas
-- distintas en pruebas manuales ('Recibida', 'en proceso'). Un CHECK cierra la
-- puerta a valores fuera del flujo de negocio real del taller.
-- ===========================================================================

-- Antes de crear el CHECK, normalizamos lo que ya existe para que la migración
-- no falle sobre datos históricos que no cumplen la nueva regla.
UPDATE ordenes_servicio
SET estado = 'recibida'
WHERE estado NOT IN ('recibida', 'en_proceso', 'entregada', 'cancelada');

ALTER TABLE ordenes_servicio
    ADD CONSTRAINT chk_ordenes_estado
    CHECK (estado IN ('recibida', 'en_proceso', 'entregada', 'cancelada'));

-- Misma restricción sobre citas, que comparte el mismo tipo de campo `estado`.
UPDATE citas
SET estado = 'agendada'
WHERE estado NOT IN ('agendada', 'confirmada', 'cancelada', 'completada');

ALTER TABLE citas
    ADD CONSTRAINT chk_citas_estado
    CHECK (estado IN ('agendada', 'confirmada', 'cancelada', 'completada'));
