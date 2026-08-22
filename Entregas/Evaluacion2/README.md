# Rueda Libre — Cloud Data Warehouse e Ingesta (Momento 2)

Proyecto propio de equipo para el Momento Evaluativo 2 del módulo *Tendencias emergentes en
desarrollo de software*. Construye, sobre el mismo dominio del Momento 1 (taller de
reparación de bicicletas "Rueda Libre"), un Data Warehouse en Snowflake con dos caminos de
ingesta gobernados: uno relacional desde Neon (no implementado en el alcance de la entrega), 
otro semi-estructurado desde un JSON externo — orquestados con Tasks nativas y protegidos con RBAC + Masking.

Decisiones de diseño (fuente JSON elegida, estrategia de roles): [`docs/decisiones_momento_2.md`](docs/decisiones_momento_2.md).

---

## Stack

- **Snowflake** — arquitectura como código, ELT relacional, External Stages (JSON), Tasks, RBAC, Dynamic Data Masking.

## Estructura

```
.
├── snowflake/
│   ├── setup/01_setup_snowflake.sql        
│   ├── json/                               
│   │   ├── 02_stage_load.sql
│   │   ├── 03_flatten_query_exploration.sql
│   │   └── data/ordenes_diagnostico.json   # subir a tu bucket S3 propio o en nuestro caso al internal stage
│   ├── setup/                              
│   │   └── 01_setup_snowflake.sql
│   ├── tasks/                             
│   │   └── 04_dag_ingesta_diagnosticos.sql
│   └── rbac/                              
│       └── 05_rbac_and_masking.sql
├── docs/
│   └── decisiones_momento_2.md             
└── .env.example                          
```

## Orden de ejecución sugerido

1. **Arquitectura** — `snowflake/setup/01_setup_snowflake.sql` en Snowsight, reemplazando `<TU_USUARIO>`.
2. **Ingesta JSON** — corre `02_stage_load.sql` hasta el comando CREATE RUEDA_LIBRE_STAGE para crear el stage, 
   luego sube el json `snowflake/json/data/ordenes_diagnostico.json` al stage creado y luego retoma la ejecución 
   de `02_stage_load.sql`. Luego aplica el flatten corriendo el archivo `03_flatten_query_exploration.sql`.
3. **DAG de Tasks** — `snowflake/tasks/04_dag_ingesta_diagnosticos.sql` (crea, activa,
   dispara y consulta `TASK_HISTORY`).
4. **RBAC + Masking** — `snowflake/rbac/05_rbac_and_masking.sql`, reemplazando los
   `<USUARIO_...>` por los integrantes reales del equipo.
