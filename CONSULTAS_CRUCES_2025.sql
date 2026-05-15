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
-- =========================================================
-- REPORTE COMPLETO DE ACEPTADOS CON DATOS CLÍNICOS Y PBX
-- (SOLO LA LLAMADA DE MAYOR DURACIÓN POR TELÉFONO)
-- BASE DE DATOS ACTUALIZADA 2025
-- =========================================================
-- TABLAS:
--   - consolidado_2025 (g)
--   - unidades_2025 (u)
--   - resultados_2025 (br)
--   - hist_pbx (hp)
--
-- Para cada teléfono, se trae ÚNICAMENTE la llamada
-- con mayor duración (evita duplicados por múltiples llamadas)
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
    g.fecha AS fecha_consolidado,
    u."fecha_de_registro_ingreso_de_la_información_dd_mm_aaaa" AS fecha_registro,
    STRING_AGG(DISTINCT g.responsable, ' | ') AS responsables,
    br.tipo_de_examen,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado,
    
    -- Datos PBX
    hp.numero_telefono,
    hp.fecha AS fecha_llamada,
    hp.duracion_llamada,
    hp.answer

FROM consolidado_2025 g
INNER JOIN unidades_2025 u
    ON g.nro_identificacion = u."número_de_identificación"::text
LEFT JOIN resultados_2025 br
    ON g.nro_identificacion = br.identificacion::text
LEFT JOIN (
    SELECT 
        numero_telefono,
        fecha,
        duracion_llamada,
        answer,
        ROW_NUMBER() OVER (
            PARTITION BY numero_telefono 
            ORDER BY duracion_llamada DESC
        ) AS rn
    FROM hist_pbx
    WHERE duracion_llamada IS NOT NULL
) hp ON g.telefono_mas_usado = hp.numero_telefono AND hp.rn = 1

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
    br.tipo_de_examen,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado,
    hp.numero_telefono,
    hp.fecha,
    hp.duracion_llamada,
    hp.answer;



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


*************

SELECT 
    TRIM(g.base_consolidada_diciembre) AS base_consolidada_diciembre,
    TRIM(g.responsable) AS responsable,

    -- REGISTROS ENCONTRADOS EN UNIDADES_2025
    COUNT(DISTINCT CASE
        WHEN u."número_de_identificación" IS NOT NULL
        THEN g.nro_identificacion
    END) AS registros_en_unidades,

    -- TOTAL_LLAMADAS: Todo excepto NULL, vacío y 'NO APLICA'
    COUNT(DISTINCT CASE 
        WHEN UPPER(TRIM(g.criterios)) IS NOT NULL
         AND UPPER(TRIM(g.criterios)) <> ''
         AND UPPER(TRIM(g.criterios)) <> 'NO APLICA'
        THEN g.nro_identificacion
    END) AS total_llamadas,
    
    -- LLAMADAS_NO_REALIZADAS:
    -- Todo excepto NULL, vacío, 'NO APLICA', 'ACEPTA' y 'NO ACEPTA'
    COUNT(DISTINCT CASE 
        WHEN UPPER(TRIM(g.criterios)) IS NOT NULL
         AND UPPER(TRIM(g.criterios)) <> ''
         AND UPPER(TRIM(g.criterios)) <> 'NO APLICA'
         AND UPPER(TRIM(g.criterios)) NOT IN ('ACEPTA', 'NO ACEPTA')
        THEN g.nro_identificacion
    END) AS llamadas_no_realizadas,
    
    -- LLAMADAS_CONTESTADAS:
    -- Todo excepto NULL, vacío, 'NO CONTESTA' y 'NO APLICA'
    COUNT(DISTINCT CASE 
        WHEN UPPER(TRIM(g.criterios)) IS NOT NULL
         AND UPPER(TRIM(g.criterios)) <> ''
         AND UPPER(TRIM(g.criterios)) NOT IN ('NO CONTESTA', 'NO APLICA')
        THEN g.nro_identificacion
    END) AS llamadas_contestadas,
    
    -- NO_ACEPTARON: Solo 'NO ACEPTA'
    COUNT(DISTINCT CASE 
        WHEN UPPER(TRIM(g.criterios)) = 'NO ACEPTA'
        THEN g.nro_identificacion
    END) AS no_aceptaron,
    
    -- ACEPTADAS: Solo 'ACEPTA'
    COUNT(DISTINCT CASE 
        WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA'
        THEN g.nro_identificacion
    END) AS aceptadas

FROM consolidado_2025 g
LEFT JOIN unidades_2025 u
    ON TRIM(g.nro_identificacion) = TRIM(u."número_de_identificación"::text)

WHERE g.responsable IS NOT NULL
  AND TRIM(g.responsable) <> ''
  AND g.base_consolidada_diciembre IS NOT NULL
  AND TRIM(g.base_consolidada_diciembre) <> ''
  AND g.criterios IS NOT NULL
  AND TRIM(g.criterios) <> ''

GROUP BY 
    TRIM(g.base_consolidada_diciembre),
    TRIM(g.responsable)

ORDER BY 
    TRIM(g.base_consolidada_diciembre),
    total_llamadas DESC;