-- ============================================================
-- ETL: Exportar tabla a CSV
-- USO: \copy (SELECT * FROM tabla) TO '/ruta/archivo.csv' WITH (FORMAT CSV, HEADER)
-- ============================================================

-- Para usar desde psql (client-side):
-- \copy ventas TO '/home/user/exports/ventas.csv' WITH (FORMAT CSV, HEADER)

-- Función para listar tablas
DROP FUNCTION IF EXISTS list_tables();

CREATE OR REPLACE FUNCTION list_tables()
RETURNS TABLE (table_name TEXT) AS $$
BEGIN
    RETURN QUERY SELECT table_name::TEXT 
    FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    ORDER BY table_name;
END;
$$ LANGUAGE plpgsql;

-- Función para contar filas
DROP FUNCTION IF EXISTS count_rows(TEXT);

CREATE OR REPLACE FUNCTION count_rows(p_table TEXT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    EXECUTE 'SELECT COUNT(*) FROM ' || p_table INTO v_count;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- Verificar estructura de tabla
DROP FUNCTION IF EXISTS table_info(TEXT);

CREATE OR REPLACE FUNCTION table_info(p_table TEXT)
RETURNS TABLE (
    column_name TEXT,
    data_type TEXT
) AS $$
BEGIN
    RETURN QUERY SELECT column_name::TEXT, data_type::TEXT
    FROM information_schema.columns
    WHERE table_name = p_table AND table_schema = 'public'
    ORDER BY ordinal_position;
END;
$$ LANGUAGE plpgsql;