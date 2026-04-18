-- ============================================================
-- ETL: Validar y eliminar valores negativos
-- USO: SELECT * FROM validate_negative('ventas', 'cantidad');
-- ============================================================

-- Función principal
DROP FUNCTION IF EXISTS validate_negative(TEXT, TEXT);

CREATE OR REPLACE FUNCTION validate_negative(
    p_table TEXT,
    p_column TEXT
)
RETURNS TABLE (
    table_name TEXT,
    column_name TEXT,
    negative_count INT,
    rows_deleted INT,
    message TEXT
) AS $$
DECLARE
    v_count INT;
    v_deleted INT;
    v_table TEXT;
    v_column TEXT;
BEGIN
    v_table := regexp_replace(p_table, '[^a-zA-Z0-9_]', '_', 'g');
    v_column := regexp_replace(p_column, '[^a-zA-Z0-9_]', '_', 'g');

    -- Contar valores negativos
    EXECUTE 'SELECT COUNT(*) FROM ' || v_table || ' WHERE ' || v_column || '::NUMERIC < 0'
    INTO v_count;

    -- Eliminar valores negativos
    EXECUTE 'DELETE FROM ' || v_table || ' WHERE ' || v_column || '::NUMERIC < 0';

    GET DIAGNOSTICS v_deleted = ROW_COUNT;

    RETURN QUERY SELECT 
        v_table::TEXT,
        v_column::TEXT,
        v_count::INT,
        v_deleted::INT,
        'Eliminados: ' || v_deleted::TEXT::TEXT;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Wrapper: TRUE/FALSE si hay negativos
-- USO: SELECT has_negative('ventas', 'total');
-- ============================================================

DROP FUNCTION IF EXISTS has_negative(TEXT, TEXT);

CREATE OR REPLACE FUNCTION has_negative(
    p_table TEXT,
    p_column TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
    v_table TEXT;
    v_column TEXT;
BEGIN
    v_table := regexp_replace(p_table, '[^a-zA-Z0-9_]', '_', 'g');
    v_column := regexp_replace(p_column, '[^a-zA-Z0-9_]', '_', 'g');

    EXECUTE 'SELECT COUNT(*) FROM ' || v_table || ' WHERE ' || v_column || '::NUMERIC < 0'
    INTO v_count;

    RETURN v_count > 0;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Verificar todas las columnas numéricas
-- USO: SELECT * FROM check_all_negative('ventas');
-- ============================================================

DROP FUNCTION IF EXISTS check_all_negative(TEXT);

CREATE OR REPLACE FUNCTION check_all_negative(
    p_table TEXT
)
RETURNS TABLE (
    column_name TEXT,
    negative_count INT
) AS $$
DECLARE
    v_table TEXT;
    rec RECORD;
    v_count INT;
BEGIN
    v_table := regexp_replace(p_table, '[^a-zA-Z0-9_]', '_', 'g');

    FOR rec IN 
        SELECT column_name::TEXT as col
        FROM information_schema.columns
        WHERE table_name = v_table 
        AND table_schema = 'public'
        AND data_type IN ('integer', 'numeric', 'double precision', 'bigint', 'smallint')
    LOOP
        BEGIN
            EXECUTE 'SELECT COUNT(*) FROM ' || v_table || ' WHERE ' || rec.col || '::NUMERIC < 0'
            INTO v_count;

            IF v_count > 0 THEN
                RETURN QUERY SELECT rec.col::TEXT, v_count::INT;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            CONTINUE;
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;