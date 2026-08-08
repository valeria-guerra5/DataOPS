# Evidencias de error

1. **Run fallido** al aplicar
   `V202608081100__add_estado_bicicleta.sql` y hacer en Neon la consulta
   `UPDATE bicicletas SET estado = 'en_reparacion' WHERE bicicleta_id = 3;` sale el error
   `ERROR: value too long for type character varying(8)`.
   <img width="1272" height="460" alt="image" src="https://github.com/user-attachments/assets/d3ddb13c-08a6-4f4b-a701-6d58bf42ccd8" />

2. **Run exitoso posterior** al aplicar
   `V202608081115__fix_estado_bicicleta_length.sql` Se vuelve a hacer la consulta y obtenemos resultado exitoso.
   <img width="1296" height="394" alt="image" src="https://github.com/user-attachments/assets/ca65122b-8d5c-42f5-bae3-c48dfc2ff627" />

