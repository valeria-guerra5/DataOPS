{#
    Override del macro estándar de dbt para nombrar schemas.

    Por defecto, dbt concatena el schema del target (profiles.yml) con el +schema
    declarado en dbt_project.yml — por ejemplo CORE_staging en vez de STAGING. Eso
    tiene sentido cuando varios desarrolladores comparten una sola base y necesitan
    aislarse por prefijo, pero acá cada capa Medallón (RAW, RAW_JSON, STAGING, CORE) ya
    es su propio schema con un nombre que cuenta la historia del dato. Este override
    hace que +schema mande solo, sin el prefijo del target — el mismo patrón que
    recomienda la documentación oficial de dbt para este caso
    (https://docs.getdbt.com/docs/build/custom-schemas).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
