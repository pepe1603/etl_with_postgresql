-- ============================================================
-- ETL Exercise: CSV Cleaning Script
-- Reads CSV, validates dates and nulls, exports clean CSV
-- USO: psql -U pepe_gope -d postgres -v file='/ruta/archivo.csv' -f clean_csv.sql
-- ============================================================

\echo '========================================='
\echo '  ETL - CSV Cleaning Script'
\echo '========================================='
\echo 'Archivo de entrada: :file'
\echo ''

-- ============================================================
-- Limpieza de objetos anteriores
-- ============================================================
DROP TABLE IF EXISTS staging_temp CASCADE;

-- ============================================================
-- PASO 1: Crear tabla staging
-- ============================================================
CREATE TEMP TABLE staging_temp (
    id SERIAL PRIMARY KEY,
    col1 TEXT,
    col2 TEXT,
    col3 TEXT,
    col4 TEXT,
    col5 TEXT
);

-- ============================================================
-- PASO 2: Importar datos del CSV a staging
-- ============================================================
\echo 'Importando datos...'
COPY staging_temp (col1, col2, col3, col4, col5)
FROM :'file'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    NULL ''
);

-- ============================================================
-- Analisis de datos importados
-- ============================================================
DO $$
DECLARE
    v_total_rows INT;
    v_null_rows INT;
    v_invalid_date_rows INT;
    v_clean_rows INT;
BEGIN
    SELECT COUNT(*) INTO v_total_rows FROM staging_temp;
    
    SELECT COUNT(*) INTO v_null_rows 
    FROM staging_temp 
    WHERE col1 IS NULL OR col2 IS NULL OR col3 IS NULL 
       OR col4 IS NULL OR col5 IS NULL;
    
    SELECT COUNT(*) INTO v_invalid_date_rows 
    FROM staging_temp 
    WHERE NOT is_valid_date(col3, 'YYYY-MM-DD', NULL, NULL, FALSE)
       OR NOT is_valid_date(col4, 'YYYY-MM-DD', NULL, NULL, FALSE);
    
    SELECT COUNT(*) INTO v_clean_rows 
    FROM staging_temp 
    WHERE col1 IS NOT NULL AND col2 IS NOT NULL AND col3 IS NOT NULL 
      AND col4 IS NOT NULL AND col5 IS NOT NULL 
      AND is_valid_date(col3, 'YYYY-MM-DD', NULL, NULL, FALSE)
      AND is_valid_date(col4, 'YYYY-MM-DD', NULL, NULL, FALSE);
    
    RAISE NOTICE '========================================';
    RAISE NOTICE '      REPORTE DE LIMPIEZA DE DATOS     ';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total de filas leidas: %', v_total_rows;
    RAISE NOTICE 'Filas con valores nulos: %', v_null_rows;
    RAISE NOTICE 'Filas con fechas invalidas: %', v_invalid_date_rows;
    RAISE NOTICE 'Filas a exportar (limpias): %', v_clean_rows;
    RAISE NOTICE '========================================';
    
    IF v_clean_rows = 0 THEN
        RAISE WARNING 'ADVERTENCIA: No hay filas para exportar!';
    END IF;
END $$;

-- ============================================================
-- PASO 3: Exportar datos limpios a CSV
-- ============================================================
\echo 'Generando archivo limpio...'

\copy (SELECT col1, col2, col3, col4, col5 FROM staging_temp WHERE col1 IS NOT NULL AND col2 IS NOT NULL AND col3 IS NOT NULL AND col4 IS NOT NULL AND col5 IS NOT NULL AND is_valid_date(col3, 'YYYY-MM-DD', NULL, NULL, FALSE) AND is_valid_date(col4, 'YYYY-MM-DD', NULL, NULL, FALSE)) TO :file WITH (FORMAT CSV, HEADER TRUE)

-- ============================================================
-- Mostrar preview de datos limpios
-- ============================================================
\echo ''
\echo 'Preview de datos limpios (max 10 filas):'
SELECT * FROM staging_temp WHERE col1 IS NOT NULL AND col2 IS NOT NULL AND col3 IS NOT NULL AND col4 IS NOT NULL AND col5 IS NOT NULL AND is_valid_date(col3, 'YYYY-MM-DD', NULL, NULL, FALSE) AND is_valid_date(col4, 'YYYY-MM-DD', NULL, NULL, FALSE) LIMIT 10;

\echo ''
\echo '========================================='
\echo '  Proceso completado!'
\echo '========================================='

-- ============================================================
-- Limpieza final
-- ============================================================
DROP TABLE IF EXISTS staging_temp;
