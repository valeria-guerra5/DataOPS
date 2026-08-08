-- ===========================================================================
-- V202608081000__baseline_taller_bicicletas.sql
--
-- Estado base del modelo transaccional de "Rueda Libre", taller de reparación
-- de bicicletas. Equivalente a lo que hizo inyeccion_semilla.py en la Sesión 1,
-- adaptado al modelo propio del equipo.
--
-- Crea las 8 tablas núcleo del negocio y las puebla con datos sintéticos.
-- `citas` NO se crea aquí a propósito: se agrega en la siguiente migración
-- evolutiva (tabla nueva), para poder demostrar ese requisito del Momento 1.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. clientes
-- ---------------------------------------------------------------------------
CREATE TABLE clientes (
    cliente_id      SERIAL PRIMARY KEY,
    nombre          VARCHAR(120) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    fecha_registro  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------------
-- 2. bicicletas — cada bicicleta pertenece a un cliente
-- ---------------------------------------------------------------------------
CREATE TABLE bicicletas (
    bicicleta_id    SERIAL PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes (cliente_id),
    marca           VARCHAR(60) NOT NULL,
    modelo          VARCHAR(60) NOT NULL,
    tipo            VARCHAR(30) NOT NULL,   -- ruta, montaña, urbana, eléctrica...
    numero_serie    VARCHAR(40)
);

CREATE INDEX idx_bicicletas_cliente ON bicicletas (cliente_id);

-- ---------------------------------------------------------------------------
-- 3. tecnicos
-- ---------------------------------------------------------------------------
CREATE TABLE tecnicos (
    tecnico_id          SERIAL PRIMARY KEY,
    nombre              VARCHAR(120) NOT NULL,
    especialidad        VARCHAR(60),
    fecha_contratacion  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------------
-- 4. servicios — catálogo fijo de servicios ofrecidos
-- ---------------------------------------------------------------------------
CREATE TABLE servicios (
    servicio_id             SERIAL PRIMARY KEY,
    nombre                  VARCHAR(100) NOT NULL,
    descripcion             TEXT,
    precio_base             NUMERIC(10, 2) NOT NULL CHECK (precio_base >= 0),
    duracion_estimada_min   INTEGER NOT NULL CHECK (duracion_estimada_min > 0)
);

-- ---------------------------------------------------------------------------
-- 5. repuestos — inventario de piezas
-- ---------------------------------------------------------------------------
CREATE TABLE repuestos (
    repuesto_id     SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    categoria       VARCHAR(60),
    precio_unitario NUMERIC(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    stock           INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

-- ---------------------------------------------------------------------------
-- 6. ordenes_servicio — una intervención sobre una bicicleta
-- ---------------------------------------------------------------------------
CREATE TABLE ordenes_servicio (
    orden_id                SERIAL PRIMARY KEY,
    bicicleta_id            INTEGER NOT NULL REFERENCES bicicletas (bicicleta_id),
    tecnico_id              INTEGER NOT NULL REFERENCES tecnicos (tecnico_id),
    fecha_ingreso            DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_entrega_estimada  DATE,
    fecha_entrega_real      DATE,
    estado                  VARCHAR(20) NOT NULL DEFAULT 'recibida',
    total                   NUMERIC(10, 2) NOT NULL DEFAULT 0
);

CREATE INDEX idx_ordenes_bicicleta ON ordenes_servicio (bicicleta_id);
CREATE INDEX idx_ordenes_tecnico   ON ordenes_servicio (tecnico_id);

-- ---------------------------------------------------------------------------
-- 7. orden_servicio_detalle — servicios aplicados en cada orden (N a N)
-- ---------------------------------------------------------------------------
CREATE TABLE orden_servicio_detalle (
    detalle_id      SERIAL PRIMARY KEY,
    orden_id        INTEGER NOT NULL REFERENCES ordenes_servicio (orden_id),
    servicio_id     INTEGER NOT NULL REFERENCES servicios (servicio_id),
    cantidad        INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    precio_aplicado NUMERIC(10, 2) NOT NULL   -- precio congelado al momento de la orden
);

CREATE INDEX idx_detalle_orden ON orden_servicio_detalle (orden_id);

-- ---------------------------------------------------------------------------
-- 8. orden_repuestos — repuestos consumidos en cada orden (N a N)
-- ---------------------------------------------------------------------------
CREATE TABLE orden_repuestos (
    orden_repuesto_id  SERIAL PRIMARY KEY,
    orden_id           INTEGER NOT NULL REFERENCES ordenes_servicio (orden_id),
    repuesto_id        INTEGER NOT NULL REFERENCES repuestos (repuesto_id),
    cantidad           INTEGER NOT NULL DEFAULT 1 CHECK (cantidad > 0),
    precio_aplicado    NUMERIC(10, 2) NOT NULL
);

CREATE INDEX idx_orden_repuestos_orden ON orden_repuestos (orden_id);

-- ===========================================================================
-- Datos sintéticos — volumen pequeño, compatible con el tier gratuito de Neon
-- ===========================================================================

INSERT INTO clientes (nombre, email, telefono) VALUES
    ('Laura Ramírez',   'laura.ramirez@example.com',   '3001110001'),
    ('Andrés Torres',   'andres.torres@example.com',   '3001110002'),
    ('Camila Ospina',   'camila.ospina@example.com',   '3001110003'),
    ('Julián Rojas',    'julian.rojas@example.com',    '3001110004'),
    ('Valentina Cruz',  'valentina.cruz@example.com',  '3001110005'),
    ('Mateo Salazar',   'mateo.salazar@example.com',   '3001110006'),
    ('Sofía Pardo',     'sofia.pardo@example.com',     '3001110007'),
    ('Nicolás Vargas',  'nicolas.vargas@example.com',  '3001110008');

INSERT INTO tecnicos (nombre, especialidad) VALUES
    ('Diego Fernández', 'transmisión'),
    ('Paula Méndez',    'frenos'),
    ('Santiago Gómez',  'ruedas y llantas'),
    ('Isabela Duarte',  'suspensión'),
    ('Camilo Herrera',  'general'),
    ('Daniela Restrepo','eléctricas');

INSERT INTO servicios (nombre, descripcion, precio_base, duracion_estimada_min) VALUES
    ('Ajuste de frenos',        'Calibración y purgado de frenos de disco o zapata', 35000, 30),
    ('Cambio de cadena',        'Reemplazo de cadena desgastada',                    45000, 25),
    ('Verdadeo de rueda',       'Centrado de rueda delantera o trasera',             30000, 40),
    ('Mantenimiento general',   'Revisión y ajuste completo de la bicicleta',        90000, 90),
    ('Cambio de pastillas',     'Reemplazo de pastillas de freno',                   25000, 20),
    ('Lubricación de transmisión', 'Limpieza y lubricación de cadena y piñones',     20000, 15),
    ('Ajuste de cambios',       'Calibración de desviadores delantero y trasero',    30000, 30),
    ('Cambio de llanta',        'Montaje de llanta nueva',                           40000, 25),
    ('Revisión de suspensión',  'Chequeo de horquilla o amortiguador',               60000, 45),
    ('Instalación de accesorios','Montaje de parrilla, guardabarros o luces',        20000, 20),
    ('Diagnóstico eléctrico',   'Revisión de sistema eléctrico en bicicletas asistidas', 50000, 40),
    ('Encauchado completo',     'Cambio de las dos llantas y cámaras',               80000, 40);

INSERT INTO repuestos (nombre, categoria, precio_unitario, stock) VALUES
    ('Cadena 9V',              'transmisión', 55000, 15),
    ('Cadena 11V',             'transmisión', 75000, 10),
    ('Pastillas orgánicas',    'frenos',      18000, 30),
    ('Pastillas metálicas',    'frenos',      22000, 25),
    ('Cámara 26"',             'ruedas',      12000, 40),
    ('Cámara 29"',             'ruedas',      14000, 35),
    ('Llanta MTB 29"',         'ruedas',      95000, 12),
    ('Llanta urbana 700c',     'ruedas',      70000, 12),
    ('Cable de freno',         'frenos',       8000, 50),
    ('Cable de cambios',       'transmisión',  8000, 50),
    ('Piñón cassette 9V',      'transmisión', 60000,  8),
    ('Puños ergonómicos',      'accesorios',  25000, 20),
    ('Guardabarros par',       'accesorios',  35000, 15),
    ('Luz delantera LED',      'accesorios',  40000, 18),
    ('Luz trasera LED',        'accesorios',  25000, 18),
    ('Kit de parches',         'ruedas',       8000, 40),
    ('Grasa para bujes',       'lubricantes',  15000, 20),
    ('Aceite lubricante',      'lubricantes',  18000, 25),
    ('Bujes de rueda',         'ruedas',       30000, 10),
    ('Parrilla trasera',       'accesorios',   45000, 10);

INSERT INTO bicicletas (cliente_id, marca, modelo, tipo, numero_serie) VALUES
    (1, 'Trek',      'Marlin 7',       'montaña',   'SN-0001'),
    (1, 'Specialized','Sirrus X',      'urbana',    'SN-0002'),
    (2, 'Giant',     'Talon 3',        'montaña',   'SN-0003'),
    (3, 'Cannondale','Quick CX',       'urbana',    'SN-0004'),
    (4, 'Scott',     'Aspect 950',     'montaña',   'SN-0005'),
    (5, 'Trek',      'Domane AL',      'ruta',      'SN-0006'),
    (6, 'Merida',    'Big Nine',       'montaña',   'SN-0007'),
    (7, 'Cube',      'Reaction',       'montaña',   'SN-0008'),
    (8, 'GT',        'Transeo',        'urbana',    'SN-0009'),
    (2, 'Bianchi',   'Via Nirone',     'ruta',      'SN-0010');

-- Órdenes de servicio, su detalle y sus repuestos: volumen intencionalmente
-- pequeño para poder trazar el ejemplo a mano en la sustentación.
INSERT INTO ordenes_servicio (bicicleta_id, tecnico_id, fecha_ingreso, fecha_entrega_estimada, fecha_entrega_real, estado, total) VALUES
    (1, 1, '2026-07-01', '2026-07-02', '2026-07-02', 'entregada', 80000),
    (2, 2, '2026-07-03', '2026-07-03', '2026-07-03', 'entregada', 43000),
    (3, 3, '2026-07-05', '2026-07-06', NULL,          'en_proceso', 0),
    (4, 5, '2026-07-08', '2026-07-08', '2026-07-08', 'entregada', 90000),
    (5, 4, '2026-07-10', '2026-07-11', NULL,          'recibida',  0),
    (6, 1, '2026-07-12', '2026-07-12', '2026-07-12', 'entregada', 55000),
    (7, 6, '2026-07-15', '2026-07-16', NULL,          'en_proceso', 0),
    (8, 2, '2026-07-18', '2026-07-18', '2026-07-18', 'entregada', 25000);

INSERT INTO orden_servicio_detalle (orden_id, servicio_id, cantidad, precio_aplicado) VALUES
    (1, 2, 1, 45000),
    (1, 6, 1, 20000),
    (2, 1, 1, 35000),
    (3, 3, 1, 30000),
    (4, 4, 1, 90000),
    (5, 9, 1, 60000),
    (6, 7, 1, 30000),
    (6, 6, 1, 20000),
    (7, 11,1, 50000),
    (8, 5, 1, 25000);

INSERT INTO orden_repuestos (orden_id, repuesto_id, cantidad, precio_aplicado) VALUES
    (1, 1, 1, 55000),
    (2, 3, 1, 18000),
    (6, 10, 1, 8000);
