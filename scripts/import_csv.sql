-- ============================================================
-- ETL Exercise: CSV Import Function
-- Imports CSV file to PostgreSQL table
-- Creates table dynamically based on CSV headers
-- ============================================================
-- USO: SELECT import_csv_to_table('/ruta/archivo.csv', 'nombre_tabla', num_columnas);
-- Default: 5 columnas
-- ============================================================

CREATE OR REPLACE FUNCTION import_csv_to_table(
    p_file_path TEXT,
    p_table_name TEXT DEFAULT 'imported_data',
    p_num_columns INT DEFAULT 5
)
RETURNS TABLE (
    status TEXT,
    table_name TEXT,
    rows_imported INT,
    message TEXT
) AS $$
DECLARE
    v_sql TEXT;
    v_rows_imported INT;
    v_i INT;
    v_col_defs TEXT;
    v_copy_cols TEXT;
BEGIN
    -- Sanitize table name
    -- Sanitizar el nombre de la tabla
    p_table_name := regexp_replace(p_table_name, '[^a-zA-Z0-9_]', '_', 'g');
    IF p_table_name = '' OR p_table_name IS NULL THEN
        p_table_name := 'imported_data';
    END IF;

    -- Validate num_columns
    -- Validar el numero de columnas
    IF p_num_columns < 1 OR p_num_columns > 100 THEN
        p_num_columns := 5;
    END IF;

    -- Drop table if exists
    -- Eliminar la tabla si existe
    EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(p_table_name) || ' CASCADE';

    -- Create staging table with fixed columns
    -- Crear la tabla de staging con las columnas fijas
    v_col_defs := '';
    v_copy_cols := '';
    
    FOR v_i IN 1..p_num_columns LOOP
        IF v_i > 1 THEN
            v_col_defs := v_col_defs || ', ';
            v_copy_cols := v_copy_cols || ', ';
        END IF;
        v_col_defs := v_col_defs || '"col' || v_i || '" TEXT';
        v_copy_cols := v_copy_cols || 'col' || v_i;
    END LOOP;

    -- Create staging table
    -- Crear la tabla de staging con la clave primaria id y las columnas definidas
    EXECUTE 'CREATE TEMP TABLE csv_staging (id SERIAL PRIMARY KEY, ' || v_col_defs || ')';

    -- Import CSV to staging (HEADER TRUE skips header row)
    -- Importar el CSV a la tabla de staging (HEADER TRUE skips header row)
    BEGIN
        v_sql := 'COPY csv_staging (' || v_copy_cols || ') FROM ' || quote_literal(p_file_path) || ' WITH (FORMAT CSV, HEADER TRUE)';
        EXECUTE v_sql;
    EXCEPTION WHEN OTHERS THEN
        DROP TABLE IF EXISTS csv_staging;
        RETURN QUERY SELECT 
            'error'::TEXT,
            p_table_name,
            0::INT,
            'Error al leer archivo: ' || SQLERRM;
        RETURN;
    END;

    -- Create final table
    -- Crear la tabla final con la clave primaria id y las columnas definidas
    EXECUTE 'CREATE TABLE ' || quote_ident(p_table_name) || ' (id SERIAL PRIMARY KEY, ' || v_col_defs || ')';

    -- Copy data from staging to final table
    -- Copiar los datos de la tabla de staging a la tabla final
    v_sql := 'INSERT INTO ' || quote_ident(p_table_name) || ' SELECT nextval(pg_get_serial_sequence(''' || quote_ident(p_table_name) || ''', ''id'')), ' || v_copy_cols || ' FROM csv_staging';
    EXECUTE v_sql;

    -- Get row count
    SELECT COUNT(*) INTO v_rows_imported FROM csv_staging;

    -- Cleanup
    DROP TABLE IF EXISTS csv_staging;

    RETURN QUERY SELECT 
        'success'::TEXT,
        p_table_name,
        v_rows_imported::INT,
        'Importacion exitosa. ' || v_rows_imported || ' filas importadas a la tabla ' || p_table_name;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Alternative: Import to existing table (append mode)
-- Importar a una tabla existente (modo append)
-- ============================================================

CREATE OR REPLACE FUNCTION append_csv_to_table(
    p_file_path TEXT,
    p_table_name TEXT
)
RETURNS TABLE (
    status TEXT,
    rows_imported INT,
    message TEXT
) AS $$
DECLARE
    v_rows_before INT;
    v_rows_after INT;
    v_rows_imported INT;
    v_sql TEXT;
BEGIN
    -- Get row count before
    -- Obtener el numero de filas antes de la importacion
    EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(p_table_name) INTO v_rows_before;

    -- Append data
    -- Copiar los datos del CSV a la tabla existente
    v_sql := 'COPY ' || quote_ident(p_table_name) || ' FROM ' || quote_literal(p_file_path) || ' WITH (FORMAT CSV, HEADER TRUE)';
    
    BEGIN
        EXECUTE v_sql;
        
        EXECUTE 'SELECT COUNT(*) FROM ' || quote_ident(p_table_name) INTO v_rows_after;
        v_rows_imported := v_rows_after - v_rows_before;
        
        RETURN QUERY SELECT 
            'success'::TEXT,
            v_rows_imported::INT,
            'Archivo importado exitosamente. ' || v_rows_imported || ' filas agregadas.';
            
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 
            'error'::TEXT,
            0::INT,
            'Error en importacion: ' || SQLERRM;
    END;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Alternative: Import with custom column names
-- NOTE: Column names provided will be used as column names in the final table
-- Nota: Los nombres de las columnas proporcionadas se usaran como nombres de las columnas en la tabla final
-- ============================================================

CREATE OR REPLACE FUNCTION import_csv_with_headers(
    p_file_path TEXT,
    p_table_name TEXT,
    p_column_names TEXT[]
)
RETURNS TABLE (
    status TEXT,
    table_name TEXT,
    rows_imported INT,
    message TEXT
) AS $$
DECLARE
    v_sql TEXT;
    v_rows_imported INT;
    v_i INT;
    v_num_cols INT;
    v_col_defs TEXT;
    v_copy_cols TEXT;
    v_insert_cols TEXT;
BEGIN
    -- Sanitize table name
    p_table_name := regexp_replace(p_table_name, '[^a-zA-Z0-9_]', '_', 'g');
    IF p_table_name = '' OR p_table_name IS NULL THEN
        p_table_name := 'imported_data';
    END IF;

    -- Drop table if exists
    -- Eliminar la tabla si existe
    EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(p_table_name) || ' CASCADE';

    v_num_cols := array_length(p_column_names, 1);
    
    -- Build column definitions using provided names (skip 'id' to avoid conflict with SERIAL)
    -- Construir las definiciones de las columnas usando los nombres proporcionados (omitir 'id' para evitar conflictos con SERIAL) si existe
    v_col_defs := '';
    v_copy_cols := '';
    v_insert_cols := '';
    FOR v_i IN 1..v_num_cols LOOP
        -- Skip 'id' column name to avoid conflict with SERIAL
        -- Omitir el nombre de la columna 'id' para evitar conflictos con SERIAL
        IF lower(p_column_names[v_i]) = 'id' THEN
            CONTINUE;
        END IF;
        
        IF v_col_defs != '' THEN
            v_col_defs := v_col_defs || ', ';
            v_insert_cols := v_insert_cols || ', ';
            v_copy_cols := v_copy_cols || ', ';
        END IF;
        -- Clean column name
        v_col_defs := v_col_defs || '"' || regexp_replace(p_column_names[v_i], '[^a-zA-Z0-9_]', '_', 'g') || '" TEXT';
        v_copy_cols := v_copy_cols || 'col' || v_i;
        v_insert_cols := v_insert_cols || '"' || regexp_replace(p_column_names[v_i], '[^a-zA-Z0-9_]', '_', 'g') || '"';
    END LOOP;

    -- Create staging table with dynamic columns
    EXECUTE 'CREATE TEMP TABLE csv_staging (' || (
        SELECT string_agg('col' || i || ' TEXT', ', ' ORDER BY i)
        FROM generate_series(1, v_num_cols) AS i
    ) || ')';

    -- Import CSV (HEADER TRUE skips header row)
    -- Importar el CSV a la tabla de staging (HEADER TRUE skips header row)
    BEGIN
        v_sql := 'COPY csv_staging FROM ' || quote_literal(p_file_path) || ' WITH (FORMAT CSV, HEADER TRUE)';
        EXECUTE v_sql;
    EXCEPTION WHEN OTHERS THEN
        DROP TABLE IF EXISTS csv_staging;
        RETURN QUERY SELECT 
            'error'::TEXT,
            p_table_name,
            0::INT,
            'Error al leer archivo: ' || SQLERRM;
        RETURN;
    END;

    -- Create final table with custom column names
    -- Crear la tabla final con la clave primaria id y las columnas definidas
    EXECUTE 'CREATE TABLE ' || quote_ident(p_table_name) || ' (id SERIAL PRIMARY KEY, ' || v_col_defs || ')';

    -- Copy data from staging to final table (omit id column, let SERIAL auto-generate)
    v_sql := 'INSERT INTO ' || quote_ident(p_table_name) || ' (' || v_insert_cols || ') ' ||
              'SELECT ' || v_copy_cols || ' FROM csv_staging';
    EXECUTE v_sql;

    -- Get row count
    -- Obtener el numero de filas importadas
    SELECT COUNT(*) INTO v_rows_imported FROM csv_staging;

    -- Cleanup
    -- Eliminar la tabla de staging
    DROP TABLE IF EXISTS csv_staging;

    RETURN QUERY SELECT 
        -- Retornar el estado de la importacion
        'success'::TEXT,
        p_table_name,
        -- Retornar el numero de filas importadas
        v_rows_imported::INT,
        'Importacion exitosa. ' || v_rows_imported || ' filas importadas a la tabla ' || p_table_name;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Usage Examples
-- ============================================================

-- Example 1: Import with default column names (col1, col2, etc.)
-- Importar con los nombres de las columnas por defecto (col1, col2, etc.)
-- SELECT * FROM import_csv_to_table('/path/to/file.csv', 'my_table', 5);


-- Example 2: Import with custom column names
-- Importar con nombres de columnas personalizados
-- SELECT * FROM import_csv_with_headers(
--     '/path/to/file.csv', 
--     'my_table', 
--     ARRAY['id', 'nombre', 'fecha_inicio', 'fecha_fin', 'estado']
-- );

-- Example 3: Append to existing table
-- Agregar datos a una tabla existente
-- SELECT * FROM append_csv_to_table('/path/to/file.csv', 'existing_table');
