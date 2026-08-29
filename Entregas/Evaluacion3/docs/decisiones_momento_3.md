# Momento 3 — Documento de decisiones

**Proyecto:** Rueda Libre (taller de reparación de bicicletas) — mismo dominio de los Momentos 1 y 2.

## 1. Arquitectura Medallón elegida

- **Silver (`models/staging/`)** — un modelo por fuente cruda, sin excepción: las 9
  tablas relacionales del Momento 1/2 (`clientes`, `bicicletas`, `tecnicos`,
  `servicios`, `repuestos`, `ordenes_servicio`, `orden_servicio_detalle`,
  `orden_repuestos`, `citas`) y la fuente semi-estructurada del Momento 2
  (`raw_ordenes_diagnostico`). Cada uno solo hace `cast`/`rename` con `source()` — el
  único modelo que hace algo más que eso es `stg_ordenes_diagnostico`, porque para un
  dato semi-estructurado el `LATERAL FLATTEN` **es** la traducción de "fuente cruda" a
  "algo con forma de tabla", no una regla de negocio (la regla de negocio sería, por
  ejemplo, decidir qué hacer con un diagnóstico duplicado — eso si viviría en Gold).
- **Gold (`models/core/`)** — dos modelos, cada uno con una pregunta de negocio
  explícita detrás (ver sección 2). Ambos usan `ref()` exclusivamente.

## 2. Modelos Gold y las preguntas que responden

### `dim_clientes_valor`

**Pregunta:** ¿cuáles son nuestros clientes de mayor valor, y a cuáles no hemos vuelto
a ver? Cruza `clientes` con `ordenes_servicio` a través de `bicicletas` (dos saltos,
porque una orden no tiene `cliente_id` directo). Es el mismo tipo de modelo que el
patrón de la Sesión 7 (`dim_orders_engagement` sobre Parch & Posey), adaptado a que en
este dominio el camino hacia el cliente pasa por la bicicleta.

### `fct_diagnosticos_externos`

**Pregunta:** de los diagnósticos que entran por el canal externo, ¿cuáles son de un
cliente que el taller ya conoce, y qué tan fiel es? Es el modelo que cumple el
requisito de cruzar **dos orígenes de datos distintos** del proyecto propio: la fuente
semi-estructurada del Momento 2 (`stg_ordenes_diagnostico`, que entra por External
Stage + `VARIANT` + `FLATTEN`) contra la base relacional de clientes del Momento 1
(`stg_clientes`).

**Por qué el cruce es por nombre normalizado, y no por una llave.** `external_order_ref`
no es una FK a ninguna tabla relacional — el diagnóstico externo es, por diseño (ver
`Entregas/Evaluacion2/docs/decisiones_momento_2.md`), un canal que ocurre *antes* de
que exista una orden de servicio formal, y el formulario externo no conoce el
`cliente_id` interno del taller. El cruce por `lower(trim(customer_name)) =
lower(trim(nombre))` es imperfecto a propósito: es exactamente el tipo de
integración con la que un equipo de datos real tiene que lidiar cuando dos sistemas
que no se hablan describen a la misma persona con dos identificadores distintos. La
columna `es_cliente_conocido` deja explícito, fila por fila, si el cruce encontró
match — nunca se oculta la incertidumbre detrás de un `INNER JOIN` que silenciosamente
descartaría los diagnósticos sin match.

## 3. Estrategia de tests

- **Genéricos** (`unique`, `not_null`, `relationships`, `accepted_values`) sobre las
  llaves primarias y foráneas de todos los modelos Silver y Gold — ver
  `models/staging/_staging__models.yml` y `models/core/_core__models.yml`.
- **`dbt-expectations`**, cada uno con una razón de negocio distinta a "la fila no está
  vacía":
  - `expect_column_values_to_be_between` sobre `stg_servicios.precio_base`,
    `stg_repuestos.stock`, `stg_ordenes_servicio.total` y `dim_clientes_valor.gasto_total`
    — ninguno de estos puede ser negativo sin que algo aguas arriba esté roto.
  - `expect_column_values_to_be_between` sobre `stg_ordenes_diagnostico.estimated_hours`
    (0–8 horas, la jornada del taller) — una estimación fuera de rango probablemente es
    un error de captura del formulario externo.
  - `expect_column_values_to_be_in_set` sobre `stg_ordenes_diagnostico.priority` — el
    canal externo solo debería mandar `normal` o `high`; si aparece un valor nuevo,
    alguien cambió el formulario sin avisarle al taller.
  - `expect_column_values_to_match_regex` sobre `stg_clientes.email` — un correo mal
    formado significa que el cliente nunca recibe la confirmación de que su bicicleta
    está lista.

## 4. Qué no cambió respecto al patrón de la Sesión 7

La estructura del proyecto (Silver → Gold, tests declarativos, documentación en
`.yml`, `dbt build` automatizado) es la misma que se practicó en clase sobre Parch &
Posey. Las decisiones propias de este equipo fueron: qué tablas entran a Silver
(las 9 + el JSON), qué dos preguntas de negocio responden los modelos Gold, y cómo
resolver el cruce entre un canal externo sin llave y el modelo transaccional interno.
