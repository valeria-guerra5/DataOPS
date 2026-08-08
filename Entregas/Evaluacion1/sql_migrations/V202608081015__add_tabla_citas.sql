-- ===========================================================================
-- V202608081015__add_tabla_citas.sql
--
-- TABLA NUEVA. Recepción pidió poder agendar un turno antes de que el cliente
-- deje la bicicleta, para no acumular gente en el mostrador un sábado.
-- ===========================================================================

CREATE TABLE citas (
    cita_id      SERIAL PRIMARY KEY,
    cliente_id   INTEGER NOT NULL REFERENCES clientes (cliente_id),
    bicicleta_id INTEGER NOT NULL REFERENCES bicicletas (bicicleta_id),
    tecnico_id   INTEGER REFERENCES tecnicos (tecnico_id),  -- puede asignarse después
    fecha_hora   TIMESTAMP NOT NULL,
    estado       VARCHAR(20) NOT NULL DEFAULT 'agendada'
);

-- La consulta más frecuente sobre esta tabla es "citas del día para este
-- técnico", así que el índice sigue el mismo criterio filtro+orden que
-- idx_orders_account_occurred de la Sesión 2.
CREATE INDEX idx_citas_tecnico_fecha ON citas (tecnico_id, fecha_hora);

COMMENT ON TABLE citas IS
    'Turno agendado por un cliente antes de convertirse en orden de servicio.';
