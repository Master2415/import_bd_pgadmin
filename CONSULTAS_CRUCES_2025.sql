-- =========================================================
-- REPORTE COMPLETO DE ACEPTADOS CON DATOS CLÍNICOS
-- BASE DE DATOS ACTUALIZADA 2025
-- =========================================================
-- TABLAS:
--   - consolidado_2025 (antes: grupo_1_60cols_2026_unificado)
--   - unidades_2025 (antes: unidades)
--   - resultados_2025 (antes: base_resultados)
--
-- Genera un listado detallado con todos los datos de unidades
-- y agrupa múltiples responsables separados por ' | '.
-- Incluye clasificación clínica y detalles de resultados.
-- =========================================================

SELECT 
    u."número_de_identificación" AS numero_documento,
    u.primer_nombre,
    u.primer_apellido,
    u.segundo_apellido,
    u."edad" AS edad,
    u.sexo,
    u.departamento,
    u.municipio,
    u.eps,
    u.auditoria_de_servicios,
    g.fecha,
    u."fecha_de_registro_ingreso_de_la_información_dd_mm_aaaa",
    STRING_AGG(DISTINCT g.responsable, ' | ') AS responsables,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado
FROM consolidado_2025 g
INNER JOIN unidades_2025 u
    ON g.nro_identificacion = u."número_de_identificación"::text
LEFT JOIN resultados_2025 br
    ON g.nro_identificacion = br.identificacion::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
GROUP BY 
    u."número_de_identificación",
    u.primer_nombre,
    u.primer_apellido,
    u.segundo_apellido,
    u."edad",
    u.sexo,
    u.departamento,
    u.municipio,
    u.eps,
    u.auditoria_de_servicios,
    g.fecha,
    u."fecha_de_registro_ingreso_de_la_información_dd_mm_aaaa",
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado;



    -- =========================================================
-- CONTAR SERVICIOS POR RESPONSABLE (TODOS LOS CRITERIOS VÁLIDOS)
-- BASE DE DATOS ACTUALIZADA 2025
-- =========================================================
-- TABLAS:
--   - consolidado_2025
--   - unidades_2025
--
-- SERVICIOS INCLUIDOS:
--   - adn
--   - mamografia
--   - citologia
--   - psa
--   - somf
--
-- MAPEO DE COLUMNAS:
--   adn        -> adn (text)
--   mamografia -> mamografia (text)
--   citologia  -> citologia (text)
--   psa        -> psa (text)
--   somf       -> somf (text)
-- =========================================================

SELECT 
    TRIM(g.responsable) AS responsable,
    -- Totales por tipo de criterio
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' THEN g.nro_identificacion END) AS total_aceptados,
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) = 'NO ACEPTA' THEN g.nro_identificacion END) AS total_no_aceptados,
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) NOT IN ('ACEPTA', 'NO ACEPTA') THEN g.nro_identificacion END) AS total_otros_criterios,
    COUNT(DISTINCT g.nro_identificacion) AS total_general,
    
    -- Servicios solo para ACEPTA
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g.adn)) = 'true' THEN 1 ELSE 0 END) AS adn,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g.mamografia)) = 'true' THEN 1 ELSE 0 END) AS mamografia,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g.citologia)) = 'true' THEN 1 ELSE 0 END) AS citologia,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g.psa)) = 'true' THEN 1 ELSE 0 END) AS psa,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g.somf)) = 'true' THEN 1 ELSE 0 END) AS somf

FROM consolidado_2025 g
INNER JOIN unidades_2025 u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE g.responsable IS NOT NULL
    AND TRIM(g.responsable) != ''
    AND g.criterios IS NOT NULL
    AND TRIM(g.criterios) != ''
GROUP BY TRIM(g.responsable)
ORDER BY total_general DESC;