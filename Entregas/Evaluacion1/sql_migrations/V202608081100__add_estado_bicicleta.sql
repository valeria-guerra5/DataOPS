-- ===========================================================================
-- V202608081100__add_estado_bicicleta.sql
--
-- Recepción quiere saber, sin abrir órdenes, si una bicicleta está activa,
-- en reparación o fue retirada por el dueño sin recogerla. Se agrega una
-- columna de estado a `bicicletas`.
--
-- ERROR DE DISEÑO INTENCIONAL (eje del roll forward de este proyecto, análogo
-- al utm_source VARCHAR(2) de la Sesión 2): el equipo estimó que el valor más
-- largo sería "retirada" (8 caracteres) y dimensionó VARCHAR(8) justo a la
-- medida. El valor real que el negocio necesita, "en_reparacion" (13
-- caracteres), no cabe. NO SE CORRIGE AQUÍ — se corrige en la migración
-- siguiente, después de que el fallo ocurra y quede documentado.
-- ===========================================================================

ALTER TABLE bicicletas
    ADD COLUMN estado VARCHAR(8) NOT NULL DEFAULT 'activa';

COMMENT ON COLUMN bicicletas.estado IS
    'Estado operativo de la bicicleta: activa, en_reparacion, retirada.';
