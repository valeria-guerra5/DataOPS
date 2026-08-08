# Evidencias de despliegue (E5)

Esta carpeta debe contener, antes de la entrega:

1. **Captura o enlace de un run exitoso** del workflow `Flyway Migrate` en la pestaña
   *Actions* del repositorio (aplicando las migraciones desde
   `V202608081000__baseline_taller_bicicletas.sql` hasta
   `V202608081045__add_constraint_estado_orden.sql`, más `R__` sin errores).
2. **Captura o enlace del run fallido** al intentar aplicar
   `V202608081100__add_estado_bicicleta.sql` seguido de un
   `UPDATE ... SET estado = 'en_reparacion'` que dispara
   `ERROR: value too long for type character varying(8)` (o, si se prueba directo en
   Neon SQL Editor, captura del error ahí).
3. **Captura o enlace del run exitoso posterior** que aplica
   `V202608081115__fix_estado_bicicleta_length.sql` y deja el pipeline en verde de nuevo.
4. Un párrafo corto (aquí mismo o en un `.md` separado) explicando: qué causó el error,
   por qué no se corrigió editando `V202608081100`, y qué hace exactamente
   `V202608081115`.

Formato sugerido: capturas de pantalla `.png` numeradas
(`01_run_exitoso_baseline_a_constraint.png`, `02_run_fallido_estado_bicicleta.png`,
`03_run_exitoso_fix_roll_forward.png`) o enlaces directos a los runs en
`https://github.com/<usuario>/<repo>/actions/runs/<id>`.
