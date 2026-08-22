# Momento 2 — Documento de decisiones

**Proyecto:** Rueda Libre (taller de reparación de bicicletas) — mismo dominio del Momento 1.

## 1. Fuente semi-estructurada elegida: `ordenes_diagnostico.json`

De las fuentes JSON evaluadas para este momento, elegimos **`ordenes_diagnostico.json`** por tres razones concretas:

- **No existe todavía en el modelo relacional.** El Momento 1 ya tiene una tabla `citas`
  para turnos agendados formalmente. `ordenes_diagnostico.json` en cambio representa
  **diagnósticos previos entrados por un canal externo** (formulario web o WhatsApp
  Business) — el momento en que un cliente describe qué le pasa a la bicicleta *antes*
  de que el taller abra una `orden_servicio` formal. Es un paso del proceso que hoy no
  tiene ningún lugar en Neon, y que el equipo de atención al cliente controla con su
  propia herramienta.
- **Tiene un array anidado real y no trivial.** `work.requested_tasks` varía entre 2 y 3
  elementos por diagnóstico y justifica el uso de `LATERAL FLATTEN`.
- **Trae un dato sensible real** (`customer.bank_account`) sobre el que aplicar la Masking
  Policy.

## 2. Estrategia de roles (RBAC)

Definimos tres roles de negocio, además del rol de servicio `TALLER_LOADER` que solo
carga datos y nunca los consulta con fines de negocio:

| Rol | Quién lo usa | Qué necesita ver |
|---|---|---|
| `ROLE_TALLER_TECNICO` | El mecánico que atiende el diagnóstico | Todo, a excepción de la cuenta bancaria del cliente. |
| `ROLE_TALLER_RECEPCION` | Quien agenda turnos y hace seguimiento | El contexto operativo completo (bicicleta, tareas solicitadas, canal de contacto), incluyendo la cuenta bancaria del cliente para poder proceder con futuros pagos. |
| `ROLE_TALLER_GERENCIA` | Dirección del taller | Métricas agregadas (volumen, prioridad, horas estimadas) — nunca necesita saber cuál es la cuenta bancaria completa del cliente detras del diagnóstico. |

## 3. Protección del dato sensible y limitación de edición

`customer_bank_account` en `STG_ORDENES_DIAGNOSTICO` es el único campo de PII de esta fuente. Diseñamos
una Masking Policy (`snowflake/rbac/05_rbac_and_masking.sql`) que muestra la cuenta bancaria completa
solo a `ROLE_TALLER_RECEPCION`, parcialmente enmascarado a `ROLE_TALLER_GERENCIA`, y
totalmente oculto a `ROLE_TALLER_TECNICO`.
