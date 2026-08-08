-- ===========================================================================
-- V202608081115__fix_estado_bicicleta_length.sql
--
-- INCIDENTE: al intentar registrar una bicicleta como "en reparación" con
--
--     UPDATE bicicletas SET estado = 'en_reparacion' WHERE bicicleta_id = 3;
--
-- Postgres respondió:
--
--     ERROR: value too long for type character varying(8)
--
-- Causa: en V202608081100 la columna `estado` se definió como VARCHAR(8),
-- calculado sobre el valor más largo ESPERADO ("retirada" = 8) sin contar
-- "en_reparacion" (13 caracteres), que es justamente el estado más usado en
-- el día a día del taller.
--
-- Este script corrige el error mediante ROLL FORWARD, no editando
-- V202608081100: esa migración ya se ejecutó y está registrada en
-- flyway_schema_history con su checksum. Editar ese archivo produciría
-- "Migration checksum mismatch" en cualquier entorno donde ya haya corrido, y
-- dejaría a dev y a main con esquemas distintos y el mismo historial —
-- exactamente el problema que Flyway existe para evitar.
-- ===========================================================================

-- Ampliar un VARCHAR es una operación de catálogo, instantánea y segura sobre
-- cualquier volumen de filas: no hay valor existente que deje de caber al
-- pasar de 8 a 20 caracteres.
ALTER TABLE bicicletas
    ALTER COLUMN estado TYPE VARCHAR(20);

-- Aprovechamos la misma migración para blindar el campo con la restricción que
-- V202608081100 debió tener desde el principio: solo estos tres valores son
-- válidos.
ALTER TABLE bicicletas
    ADD CONSTRAINT chk_bicicletas_estado
    CHECK (estado IN ('activa', 'en_reparacion', 'retirada'));

COMMENT ON COLUMN bicicletas.estado IS
    'Estado operativo de la bicicleta: activa, en_reparacion, retirada. '
    'Ampliado de VARCHAR(8) a VARCHAR(20) el 2026-08-08 tras fallo en producción '
    '(no cabía "en_reparacion").';
