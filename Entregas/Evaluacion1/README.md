
# Rueda Libre — CI/CD de base de datos (Momento 1)

Proyecto propio de equipo para el Momento 1 del módulo *Tendencias emergentes en
desarrollo de software*. Modelo transaccional de un taller de reparación de bicicletas,
versionado con Flyway y desplegado con GitHub Actions sobre Neon (PostgreSQL).

Ver el [documento de dominio de negocio y diagrama ER](docs/dominio_de_negocio.md).

Enunciado del ejercicio: [Momento 1 — CI/CD en Base de Datos](../evaluaciones/momento_1_cicd_bd.md)
(ajustar o quitar este enlace si el repositorio se sube de forma independiente).

---

## Stack

- **Neon.tech** (PostgreSQL) — branches `dev` y `main`.
- **Flyway** — migraciones versionadas (`V__`) y repetibles (`R__`).
- **GitHub Actions** — despliegue automático hacia `main`.

## Requisitos previos

```bash
git --version
flyway -v        # brew install flyway (macOS) / ver docs.flyway.org
docker --version # la CLI local no lo necesita, pero el pipeline sí lo usa
```

Dos branches en un proyecto de Neon (Neon Console → *Branches*):

| Branch | Uso |
|---|---|
| `dev` | Desarrollo local, aquí corres `flyway migrate` desde tu máquina |
| `main` | Producción. **Solo la migra el pipeline de GitHub Actions.** |

## Configuración local (branch `dev`)

```bash
cp flyway.conf.example flyway.conf
```

Edita `flyway.conf` con el connection string de tu branch `dev` (Neon Console →
*Dashboard* → *Connection string*), traducido a formato JDBC como indica el propio
archivo. `flyway.conf` está en `.gitignore`: nunca se sube.

```bash
flyway info      # qué migraciones están pendientes
flyway migrate   # aplica todas las migraciones pendientes sobre dev
```

`main` no requiere bootstrap manual: nace vacía en Neon y `V202608081000__baseline_taller_bicicletas.sql`
es la primera migración que corre contra ella — la aplica el pipeline en el primer push.

## Cómo agregar una migración nueva

1. Decide si es **versionada** (`V__`, cambia estructura o datos de forma irreversible:
   tabla nueva, columna, índice, restricción) o **repetible** (`R__`, recreable desde cero
   sin efectos secundarios: función, procedimiento, vista).
2. Nombra el archivo:
   - Versionada: `V<AAAAMMDDHHMM>__descripcion_corta.sql` (timestamp, no un número
     secuencial — evita colisiones entre integrantes trabajando en paralelo).
   - Repetible: `R__descripcion_corta.sql`.
3. Colócalo en `sql_migrations/`.
4. Pruébalo local contra `dev`: `flyway migrate`.
5. Commit + push a `main`. El workflow de GitHub Actions aplica el cambio automáticamente.

**Nunca** edites un archivo `V__` que ya se ejecutó — Flyway lo rechaza por checksum. Los
errores se corrigen con una migración nueva (*roll forward*), como en
`V202608081115__fix_estado_bicicleta_length.sql` de este repositorio.

## Migraciones incluidas

| Archivo | Tipo | Qué hace |
|---|---|---|
| `V202608081000__baseline_taller_bicicletas.sql` | Versionada | Esquema base (8 tablas) + datos sintéticos |
| `V202608081015__add_tabla_citas.sql` | Versionada | Tabla nueva: `citas` |
| `V202608081030__add_columnas_fidelidad_y_notas.sql` | Versionada | Columnas nuevas: `clientes.nivel_fidelidad`, `ordenes_servicio.notas` |
| `V202608081045__add_constraint_estado_orden.sql` | Versionada | `CHECK` sobre `estado` en `ordenes_servicio` y `citas` |
| `R__fn_calcular_total_orden.sql` | Repetible | Función + procedimiento para calcular y persistir el total de una orden |
| `V202608081100__add_estado_bicicleta.sql` | Versionada | Columna `bicicletas.estado` — **`VARCHAR(8)`, error intencional** |
| `V202608081115__fix_estado_bicicleta_length.sql` | Versionada | Roll forward: amplía a `VARCHAR(20)` y agrega el `CHECK` correspondiente |

Ver el detalle del incidente y su corrección en [`docs/evidencias/`](docs/evidencias/).

## Workflow de GitHub Actions

[`.github/workflows/flyway-migrate.yml`](.github/workflows/flyway-migrate.yml) se dispara en
cada push a `main` que toque `sql_migrations/`. Traduce el connection string de Neon
(formato URI) a JDBC, corre `flyway validate` y luego `flyway migrate` usando la imagen
oficial `flyway/flyway:13.1.0-alpine`.

### Secreto requerido

En GitHub → *Settings* → *Secrets and variables* → *Actions* → **New repository secret**:

| Nombre | Valor |
|---|---|
| `NEON_MAIN_DATABASE_URL` | Connection string completo de la branch `main` de Neon |

Cero credenciales en el repositorio: el secreto vive solo en GitHub Secrets.

## Estructura del repositorio

```
.
├── .github/workflows/flyway-migrate.yml
├── docs/
│   ├── dominio_de_negocio.md   # descripción del dominio + diagrama ER (Mermaid)
│   └── evidencias/             # capturas/enlaces de runs exitosos y fallidos
├── sql_migrations/
├── flyway.conf.example
├── .gitignore
└── README.md
```
