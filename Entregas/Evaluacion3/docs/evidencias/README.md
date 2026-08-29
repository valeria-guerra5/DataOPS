# Evidencias — Momento 3

Esta carpeta se completa con evidencia real, generada al correr el proyecto contra tu
propia cuenta de Snowflake y tu propio repositorio — no se puede generar desde aquí
sin esas credenciales.

## 1. `dbt build` local

```bash
cd Entregas/Evaluacion3
set -a && source .env && set +a
uv run dbt deps --profiles-dir .
uv run dbt build --profiles-dir .
```

Guarda aquí la salida completa (`dbt_build_local.txt` o una captura) mostrando todos
los modelos y tests en verde.

## 2. Lineage graph (E3)

```bash
uv run dbt docs generate --profiles-dir .
uv run dbt docs serve --profiles-dir .
```

Toma una captura del grafo completo (Silver → Gold, con las flechas de `ref()`/
`source()` visibles) y guárdala aquí como `lineage_graph.png`.

## 3. Ejecución exitosa del workflow de GitHub Actions (E4)

Después de configurar los Secrets (ver `README.md` del proyecto) y hacer push a
`main`, guarda aquí:

- El enlace al run exitoso: `Actions` → `dbt Build` → el run más reciente en verde.
- Una captura del resumen (`GITHUB_STEP_SUMMARY`) del run.

## 4. Demo del cambio en vivo (para la sustentación, E6)

Antes de la sesión 8, ensaya el ciclo completo una vez y anota aquí los pasos exactos
que vas a repetir en vivo:

1. Columna o modelo que vas a agregar/modificar (sugerencia: agregar
   `dias_desde_ultima_orden` a `dim_clientes_valor`, usando `datediff` contra
   `current_date()`).
2. Commit y push.
3. Tiempo real que tardó el workflow en correr (para no improvisar el timing en los 7
   minutos que tienes en la sustentación).
4. Captura de la tabla en Snowsight mostrando la columna nueva ya poblada.
