{#
    Override dbt's default schema naming.

    By default dbt prefixes a custom schema with the target schema, so marts
    with `+schema: gold` would land in `silver_gold`. Production should use the
    bare medallion names, so the custom schema is used as is.

    The ci target keeps the default prefix (`ci_gold`), so CI runs stay in
    their own schemas and never write to production.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- elif target.name == 'ci' -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
