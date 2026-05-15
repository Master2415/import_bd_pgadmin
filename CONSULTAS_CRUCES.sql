/* =========================================================
   CONSULTAS DE ANÁLISIS Y CRUCE DE INFORMACIÓN
   Base de datos PostgreSQL
   
   TABLAS INVOLUCRADAS:
   - grupo_1_60cols_2026_unificado: Tabla principal con datos de gestión
   - unidades: Tabla con datos demográficos y de afiliación
   - base_resultados: Tabla con clasificaciones clínicas y detalles de resultados
   
   AUTOR: [Tu nombre]
   FECHA: [Fecha actual]
   ========================================================= */

-- =========================================================
-- 1. CONSULTAR RESPONSABLES ÚNICOS
-- =========================================================
-- Obtiene todos los nombres de responsables sin repetir.
-- Útil para:
--   - Identificar duplicados
--   - Validar nombres
--   - Limpiar datos
-- =========================================================

SELECT DISTINCT responsable
FROM grupo_1_60cols_2026_unificado;


-- =========================================================
-- 2. CONSULTAR ESTRUCTURA DE LA TABLA
-- =========================================================
-- Muestra:
--   - nombre de columnas
--   - tipo de dato de cada columna
-- Útil para:
--   - Conocer la estructura de la tabla
--   - Validar tipos de datos antes de hacer JOIN
--   - Identificar nombres exactos de columnas
-- =========================================================

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'grupo_1_60cols_2026_unificado';


-- =========================================================
-- 3. CONTAR DOCUMENTOS CRUZADOS ENTRE TABLAS
-- =========================================================
-- Proceso:
--   1. Busca registros en grupo_1_60cols_2026_unificado donde criterios = 'ACEPTA'
--   2. Toma el nro_identificacion
--   3. Busca esos documentos en la tabla unidades
--   4. Cuenta cuántos documentos existen en ambas tablas
-- DISTINCT evita contar documentos repetidos.
-- =========================================================

SELECT COUNT(DISTINCT u."número_de_identificación") AS total_encontrados
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA';


-- =========================================================
-- 4. CONTAR ACEPTADOS POR RESPONSABLE (con cruce en unidades)
-- =========================================================
-- Cuenta cuántos documentos ACEPTA tiene cada responsable
-- que también existen en la tabla unidades.
-- COALESCE convierte valores nulos en 'Null' para mejor visualización.
-- =========================================================

SELECT 
    COALESCE(TRIM(g.responsable), 'Null') AS responsable,
    COUNT(DISTINCT g.nro_identificacion) AS total_aceptados
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
GROUP BY TRIM(g.responsable)
ORDER BY total_aceptados DESC;


-- =========================================================
-- 5. CONTAR ACEPTADOS POR RESPONSABLE CON TOTAL GENERAL
-- =========================================================
-- Misma consulta anterior pero con una fila adicional 
-- que suma el total general usando ROLLUP.
-- La fila TOTAL aparece al final gracias al ORDER BY condicional.
-- =========================================================

SELECT 
    COALESCE(TRIM(g.responsable), 'Null') AS responsable,
    COUNT(DISTINCT g.nro_identificacion) AS total_aceptados
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
GROUP BY ROLLUP(TRIM(g.responsable))
ORDER BY 
    CASE WHEN TRIM(g.responsable) IS NULL THEN 1 ELSE 0 END,
    total_aceptados DESC;


-- =========================================================
-- 6. VERIFICAR DOCUMENTOS DUPLICADOS POR RESPONSABLE ESPECÍFICO
-- =========================================================
-- Muestra los documentos de un responsable específico
-- y cuántas veces aparece cada uno en la tabla.
-- Útil para detectar duplicados o múltiples gestiones sobre un mismo documento.
-- =========================================================

SELECT 
    g.nro_identificacion,
    COUNT(*) AS repeticiones
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
    AND g.responsable = 'Valentina Gutierrez'
GROUP BY g.nro_identificacion
ORDER BY repeticiones DESC;


-- =========================================================
-- 7. VERIFICAR REGISTROS CON RESPONSABLE NULO O VACÍO
-- =========================================================
-- Identifica registros ACEPTA que no tienen responsable asignado.
-- Útil para:
--   - Control de calidad de datos
--   - Asignar responsables pendientes
--   - Auditar procesos de carga de información
-- =========================================================

SELECT *
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
    AND (
        g.responsable IS NULL
        OR TRIM(g.responsable) = ''
    );


-- =========================================================
-- 8. CONSULTAR DETALLE POR RESPONSABLE ESPECÍFICO
-- =========================================================
-- Muestra los campos clave del cruce para un responsable determinado.
-- Útil para:
--   - Validar que los datos del cruce sean correctos
--   - Depurar inconsistencias
-- =========================================================

SELECT 
    g.nro_identificacion,
    g.responsable,
    g.criterios,
    u."número_de_identificación"
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE UPPER(TRIM(g.criterios)) = 'ACEPTA'
    AND g.responsable = 'Valentina Gutierrez';


-- =========================================================
-- 9. REPORTE COMPLETO DE ACEPTADOS POR RESPONSABLE
-- =========================================================
-- Genera un listado detallado con todos los datos de unidades
-- y agrupa múltiples responsables separados por ' | '.
-- STRING_AGG permite ver todos los responsables que gestionaron
-- un mismo documento cuando hay múltiples registros.
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
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa",
    STRING_AGG(DISTINCT g.responsable, ' | ') AS responsables
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
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
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa";


-- =========================================================
-- 10. REPORTE COMPLETO CON DATOS CLÍNICOS
-- =========================================================
-- Versión mejorada del reporte anterior que incluye:
--   - LEFT JOIN con base_resultados para traer clasificación clínica
--   - detalles del resultado
-- LEFT JOIN asegura que se muestren todos los registros ACEPTA
-- incluso si no tienen correspondencia en base_resultados.
-- =========================================================
 --- en uso actual
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
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa",
    STRING_AGG(DISTINCT g.responsable, ' | ') AS responsables,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado
FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
LEFT JOIN base_resultados br
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
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa",
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado;

-- =========================================================
-- CONTAR SERVICIOS POR RESPONSABLE (TODOS LOS CRITERIOS VÁLIDOS)
-- =========================================================
-- Cuenta por responsable cuántos registros tienen valor 'true'
-- en cada una de las columnas de servicios.
-- 
-- MAPEO DE COLUMNAS:
--   â°   (text) -> adn
--   â°1  (text) -> mamografia
--   â°2  (text) -> citologia
--   â°3  (text) -> psa
--   â°4  (text) -> somf
--
-- INCLUYE:
--   - total_aceptados: registros con criterio = 'ACEPTA'
--   - total_no_aceptados: registros con criterio = 'NO ACEPTA'
--   - total_otros_criterios: registros con cualquier otro criterio válido
--   - total_general: suma de todos los criterios válidos
--
-- FILTROS:
--   - Solo responsables con valor NO nulo y NO vacío
--   - Solo criterios con valor NO nulo y NO vacío (todos los criterios válidos)
-- =========================================================
 --- en uso actual
SELECT 
    TRIM(g.responsable) AS responsable,
    -- Totales por tipo de criterio
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' THEN g.nro_identificacion END) AS total_aceptados,
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) = 'NO ACEPTA' THEN g.nro_identificacion END) AS total_no_aceptados,
    COUNT(DISTINCT CASE WHEN UPPER(TRIM(g.criterios)) NOT IN ('ACEPTA', 'NO ACEPTA') THEN g.nro_identificacion END) AS total_otros_criterios,
    COUNT(DISTINCT g.nro_identificacion) AS total_general,
    
    -- Servicios solo para ACEPTA
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g."â°")) = 'true' THEN 1 ELSE 0 END) AS adn,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g."â°1")) = 'true' THEN 1 ELSE 0 END) AS mamografia,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g."â°2")) = 'true' THEN 1 ELSE 0 END) AS citologia,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g."â°3")) = 'true' THEN 1 ELSE 0 END) AS psa,
    SUM(CASE WHEN UPPER(TRIM(g.criterios)) = 'ACEPTA' AND LOWER(TRIM(g."â°4")) = 'true' THEN 1 ELSE 0 END) AS somf

FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
WHERE g.responsable IS NOT NULL
    AND TRIM(g.responsable) != ''
    AND g.criterios IS NOT NULL
    AND TRIM(g.criterios) != ''
GROUP BY TRIM(g.responsable)
ORDER BY total_general DESC;

****************************
-- =========================================================
-- REPORTE COMPLETO DE ACEPTADOS CON DATOS CLÍNICOS Y PBX
-- (SOLO LA LLAMADA DE MAYOR DURACIÓN POR TELÉFONO)
-- =========================================================
-- TABLAS:
--   - grupo_1_60cols_2026_unificado (g)
--   - unidades (u)
--   - base_resultados (br)
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
    g.fecha,
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa",
    STRING_AGG(DISTINCT g.responsable, ' | ') AS responsables,
    br.tipo_de_examen,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado,
    
    -- Datos PBX (usando ROW_NUMBER como en la primera consulta)
    hp.numero_telefono,
    hp.fecha AS fecha_llamada,
    hp.duracion_llamada,
    hp.answer

FROM grupo_1_60cols_2026_unificado g
INNER JOIN unidades u
    ON g.nro_identificacion = u."número_de_identificación"::text
LEFT JOIN base_resultados br
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
    u."fecha_de_registro-ingreso_de_la_información_dd/mm/aaaa",
    br.tipo_de_examen,
    br.clasificacion_clinica_del_resultado,
    br.detalles_del_resultado,
    hp.numero_telefono,
    hp.fecha,
    hp.duracion_llamada,
    hp.answer;


    ************************


    ***************


SELECT 
    -- Nombre del archivo de origen
    TRIM(g.archivo_origen) AS archivo_origen,

    -- Responsable
    TRIM(g.responsable) AS responsable,

    -- REGISTROS ENCONTRADOS EN UNIDADES
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

FROM grupo_1_60cols_2026_unificado g
LEFT JOIN unidades u
    ON TRIM(g.nro_identificacion) = TRIM(u."número_de_identificación"::text)

WHERE g.responsable IS NOT NULL
  AND TRIM(g.responsable) <> ''
  AND g.archivo_origen IS NOT NULL
  AND TRIM(g.archivo_origen) <> ''
  AND g.criterios IS NOT NULL
  AND TRIM(g.criterios) <> ''

GROUP BY 
    TRIM(g.archivo_origen),
    TRIM(g.responsable)

ORDER BY 
    archivo_origen,
    total_llamadas DESC;