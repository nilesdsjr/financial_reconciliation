{% macro rename_and_cast(source, model_ref) %}
{%- set mapping = yaml_load_file('mappings/column_map.yml')[source] -%}
{%- for raw, std in mapping.items() %}
    {{ adapter.quote(raw) }} AS {{ std }}{% if not loop.last %}, {% endif %}
{%- endfor %}
{% endmacro %}
