# Rueda Libre — End-to-End DataOps (Momento 3)

Proyecto dbt sobre el dominio de "Rueda Libre" (taller de reparación de bicicletas),
construido sobre lo que dejaron el Momento 1 (Neon versionado con Flyway) y el
Momento 2 (ingesta relacional + semi-estructurada gobernada hacia Snowflake).

Enunciado completo y rúbrica: [`momento_3_e2e_dataops.md`](momento_3_e2e_dataops.md).
Decisiones de diseño (por qué estos dos modelos Gold, por qué el cruce por nombre):
[`docs/decisiones_momento_3.md`](docs/decisiones_momento_3.md).

---

## Arquitectura Medallón

```
RAW / RAW_JSON (Momento 2)
        │  source()
        ▼
models/staging/   (Silver — cast, rename, LATERAL FLATTEN del JSON. VIEW.)
        │  ref()
        ▼
models/core/       (Gold — joins, agregaciones, cruce de orígenes. TABLE.)
```

| Capa | Modelo | Qué es |
|---|---|---|
| Silver | `stg_clientes`, `stg_bicicletas`, `stg_tecnicos`, `stg_servicios`, `stg_repuestos`, `stg_ordenes_servicio`, `stg_orden_servicio_detalle`, `stg_orden_repuestos`, `stg_citas` | Una tabla relacional del Momento 1/2 cada una, sin transformar. |
| Silver | `stg_ordenes_diagnostico` | El JSON de diagnósticos externos del Momento 2, aplanado con `LATERAL FLATTEN`. |
| Gold | `dim_clientes_valor` | Valor histórico de cada cliente (órdenes, gasto, última visita). |
| Gold | `fct_diagnosticos_externos` | Cruce entre el canal de diagnóstico externo y la base de clientes — el modelo que cruza dos orígenes distintos. |

## Cómo correrlo

```bash
cd Entregas/Evaluacion3
cp .env.example .env               # completa tus credenciales reales de Snowflake
cp profiles.yml.example profiles.yml   # no requiere cambios: todo se lee de .env

set -a && source .env && set +a
uv run dbt deps --profiles-dir .
uv run dbt build --profiles-dir .

# Documentación y lineage graph:
uv run dbt docs generate --profiles-dir .
uv run dbt docs serve --profiles-dir .
```

Si `Entregas/Evaluacion3` todavía no tiene un `pyproject.toml` propio para el entorno
de dbt, créalo una vez con:

```bash
uv init --name dbt-rueda-libre --python 3.12 --no-readme
uv add "dbt-core~=1.8.0" "dbt-snowflake~=1.8.0"
```

## Automatización (E4)

El workflow vive en la raíz del repositorio: `.github/workflows/dbt-build.yml`. Corre
`dbt build` en cada push a `main` que toque esta carpeta. Configura estos Secrets antes
del primer push (`Settings` → `Secrets and variables` → `Actions`):

```
SNOWFLAKE_ACCOUNT
SNOWFLAKE_USER
SNOWFLAKE_PASSWORD
SNOWFLAKE_ROLE       (DATAOPS_LOADER)
SNOWFLAKE_WAREHOUSE  (WH_TALLER)
SNOWFLAKE_DATABASE   (RUEDA_LIBRE)
SNOWFLAKE_SCHEMA     (CORE)
```

## Checklist contra la rúbrica (`momento_3_e2e_dataops.md`, sección 6)

- [ ] **C1** `dbt run`/`dbt build` compila sin errores; Silver solo hace `source()` + cast/rename, Gold solo usa `ref()`.
- [ ] **C2** Los dos modelos Gold responden una pregunta de negocio explícita (ver `docs/decisiones_momento_3.md`); `fct_diagnosticos_externos` cruza dos orígenes.
- [ ] **C3** Tests genéricos sobre llaves/relaciones de todos los modelos; ≥2 tests de `dbt-expectations` con justificación (hay 5 en este proyecto).
- [ ] **C4** Workflow corrido al menos una vez con éxito — evidencia en `docs/evidencias/`.
- [ ] **C5** `dbt docs generate` produce un lineage graph legible; captura guardada en `docs/evidencias/`; demo del cambio en vivo ensayada.

## Nota sobre `external_order_ref`

`fct_diagnosticos_externos` cruza `stg_ordenes_diagnostico` con `stg_clientes` **por
nombre normalizado**, no por una llave — el canal externo no comparte ningún
identificador con el modelo transaccional interno. Es una decisión de diseño
explicada en `docs/decisiones_momento_3.md`, no una limitación técnica sin resolver.
