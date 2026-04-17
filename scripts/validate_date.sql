-- ============================================================
-- Date Validation Utility Function for PostgreSQL
-- Validates dates with format checking, range validation, and timezone support
-- ============================================================
-- Fecha de Validacion Utilitario para PostgreSQL
-- Validacion de fechas con formato, rango, y soporte para zona horaria
-- ============================================================


-- Drop function if exists for recreation
-- Eliminar funcion si existe para recrearla
DROP FUNCTION IF EXISTS validate_date(
    p_date TEXT,
    p_format TEXT,
    p_min_date TEXT,
    p_max_date TEXT,
    p_reject_future BOOLEAN
);

-- Main validation function
-- validacion de fecha principal
CREATE OR REPLACE FUNCTION validate_date(
    p_date TEXT,
    p_format TEXT DEFAULT 'YYYY-MM-DD',
    p_min_date TEXT DEFAULT NULL,
    p_max_date TEXT DEFAULT NULL,
    p_reject_future BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    is_valid BOOLEAN,
    status TEXT,
    parsed_date TIMESTAMP WITH TIME ZONE,
    message TEXT
) AS $$
DECLARE
    v_parsed_date TIMESTAMP WITH TIME ZONE;
    v_min TIMESTAMP WITH TIME ZONE;
    v_max TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Check if date is null or empty
    -- Verificar si la fecha es nula o vacia
    IF p_date IS NULL OR TRIM(p_date) = '' THEN
        RETURN QUERY SELECT FALSE, 'empty', NULL::TIMESTAMP WITH TIME ZONE, 'Date cannot be empty';
        RETURN;
    END IF;

    -- Attempt to parse the date based on format
    -- Intentar parsear la fecha basado en el formato
    BEGIN
        -- Handle timezone in input (convert to TIMESTAMP WITH TIME ZONE)
        -- Manejar zona horaria en la entrada (convertir a TIMESTAMP WITH TIME ZONE)
        v_parsed_date := p_date::TIMESTAMP WITH TIME ZONE;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT FALSE, 'invalid_format', NULL::TIMESTAMP WITH TIME ZONE, 'Invalid date format: ' || p_date;
        RETURN;
    END;

    -- Convert min_date if provided
    -- Convertir min_date si se proporciona
    IF p_min_date IS NOT NULL THEN
        BEGIN
            v_min := p_min_date::TIMESTAMP WITH TIME ZONE;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT FALSE, 'invalid_min_date', NULL::TIMESTAMP WITH TIME ZONE, 'Invalid min_date format';
            RETURN;
        END;
    END IF;

    -- Convert max_date if provided
    -- Convertir max_date si se proporciona
    IF p_max_date IS NOT NULL THEN
        BEGIN
            v_max := p_max_date::TIMESTAMP WITH TIME ZONE;
        EXCEPTION WHEN OTHERS THEN
            RETURN QUERY SELECT FALSE, 'invalid_max_date', NULL::TIMESTAMP WITH TIME ZONE, 'Invalid max_date format';
            RETURN;
        END;
    END IF;

    -- Validate minimum date
    -- Validar fecha minima si se proporciona
    IF v_min IS NOT NULL AND v_parsed_date < v_min THEN
        RETURN QUERY SELECT FALSE, 'below_minimum', v_parsed_date, 'Date is before minimum allowed: ' || p_min_date;
        RETURN;
    END IF;

    -- Validate maximum date
    -- Validar fecha maxima
    IF v_max IS NOT NULL AND v_parsed_date > v_max THEN
        RETURN QUERY SELECT FALSE, 'exceeds_maximum', v_parsed_date, 'Date exceeds maximum allowed: ' || p_max_date;
        RETURN;
    END IF;

    -- Validate future dates if rejection is enabled
    -- Validar fechas futuras si se rechazan
    IF p_reject_future AND v_parsed_date > NOW() THEN
        RETURN QUERY SELECT FALSE, 'future_date', v_parsed_date, 'Future dates are not allowed';
        RETURN;
    END IF;

    -- All validations passed
    -- Todas las validaciones pasaron
    RETURN QUERY SELECT TRUE, 'valid', v_parsed_date, 'Date is valid';

END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Simple wrapper function that returns just boolean
-- ============================================================
-- Funcion wrapper que retorna solo booleano

-- Eliminar funcion si existe para recrearla
DROP FUNCTION IF EXISTS is_valid_date(TEXT, TEXT, TEXT, TEXT, BOOLEAN);

-- Funcion wrapper que retorna solo booleano
-- Crear funcion wrapper que retorna solo booleano
CREATE OR REPLACE FUNCTION is_valid_date(
    p_date TEXT,
    p_format TEXT DEFAULT 'YYYY-MM-DD',
    p_min_date TEXT DEFAULT NULL,
    p_max_date TEXT DEFAULT NULL,
    p_reject_future BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT is_valid FROM validate_date(p_date, p_format, p_min_date, p_max_date, p_reject_future));
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Usage Examples
-- ============================================================

-- Test 1: Valid date
-- SELECT * FROM validate_date('2024-01-15');

-- Test 2: Date with timezone
-- SELECT * FROM validate_date('2024-01-15 14:30:00-05:00');

-- Test 3: Date with min/max range
-- SELECT * FROM validate_date('2024-01-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Test 4: Reject future dates
-- SELECT * FROM validate_date('2030-01-01', 'YYYY-MM-DD', NULL, NULL, TRUE);

-- Test 5: Invalid format
-- SELECT * FROM validate_date('15-01-2024');

-- Simple boolean check
-- SELECT is_valid_date('2024-01-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Test 6: Invalid date
-- SELECT is_valid_date('2024-01-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Test 7: Invalid date with parameters only
-- SELECT is_valid_date('2024-01-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- ============================================================
-- HOW TO USE / COMO USAR
-- ============================================================

-- -------------------------------------------------------
-- FROM INSIDE PSQL (terminal de PostgreSQL):
-- -------------------------------------------------------

-- 1. Load the function into the database
--    Ejecutar el script en la base de datos:
-- \i validate_date.sql

-- 2. Use the function in a query
--    Usar la funcion en una consulta:

-- Basic usage (uso basico):
-- SELECT * FROM validate_date('2024-01-15');

-- With date range (con rango de fechas):
-- SELECT * FROM validate_date('2024-06-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Reject future dates ( Rechazar fechas futuras):
-- SELECT * FROM validate_date('2030-01-01', NULL, NULL, NULL, TRUE);

-- Use wrapper for simple boolean check (usar wrapper para booleano simple):
-- SELECT is_valid_date('2024-01-15');

-- Use in WHERE clause (usar en clausula WHERE):
-- SELECT * FROM my_table WHERE is_valid_date(date_column);


-- -------------------------------------------------------
-- FROM COMMAND LINE (terminal del sistema):
-- -------------------------------------------------------

-- Execute script and run tests in one command:
-- psql -U userPostgres -d postgres -f validate_date.sql

-- Run specific test:
-- psql -U userPostgres -d postgres -c "SELECT * FROM validate_date('2024-01-15');"

-- Run multiple tests with UNION ALL:
-- psql -U userPostgres -d postgres -c "
-- SELECT 'Test 1: Valid date' as test, * FROM validate_date('2024-01-15')
-- UNION ALL
-- SELECT 'Test 2: Invalid format' as test, * FROM validate_date('invalid-date')
-- UNION ALL
-- SELECT 'Test 3: Out of range' as test, * FROM validate_date('2024-06-15', 'YYYY-MM-DD', '2024-01-01', '2024-05-31');
-- "
--Run especifict test sin parsed date
-- psql -U userPostgres -d postgres -c "SELECT * FROM validate_date('2024-01-15');"


-- ============================================================
-- PARAMETER REFERENCE / REFERENCIA DE PARAMETROS
-- ============================================================

-- p_date         (TEXT): Date string to validate
-- p_format       (TEXT): Expected format (default 'YYYY-MM-DD')
-- p_min_date     (TEXT): Minimum allowed date (optional)
-- p_max_date     (TEXT): Maximum allowed date (optional)
-- p_reject_future (BOOLEAN): Reject dates in the future (default FALSE)

-- Returns: TABLE (is_valid, status, parsed_date, message)

-- init server 
-- /usr/local/opt/postgresql@14/bin/pg_ctl -D /usr/local/var/postgresql@14/data -l /usr/local/var/postgresql@14/logfile start

