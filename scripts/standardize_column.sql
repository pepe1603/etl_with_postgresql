-- ============================================================
-- ETL: Estandarizar String (Mayúsculas/Minúsculas)
-- Función principal + Wrapper como validate_date/is_valid_date
-- ============================================================

-- Función principal
DROP FUNCTION IF EXISTS standardize_string_mayus_minus(
    p_string TEXT,
    p_case TEXT,
    p_convertir BOOLEAN
);

CREATE OR REPLACE FUNCTION standardize_string_mayus_minus(
    p_string TEXT,
    p_case TEXT DEFAULT 'lower',
    p_convertir BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    is_valid BOOLEAN,
    status TEXT,
    converted_string TEXT,
    message TEXT
) AS $$
DECLARE
    v_result TEXT;
BEGIN
    -- Si es nulo o vacío
    IF p_string IS NULL OR TRIM(p_string) = '' THEN
        RETURN QUERY SELECT FALSE, 'empty', NULL::TEXT, 'String no puede ser vacío';
        RETURN;
    END IF;

    -- Convertir según el caso
    IF p_case = 'lower' THEN
        v_result := LOWER(p_string);
    ELSIF p_case = 'upper' THEN
        v_result := UPPER(p_string);
    ELSE
        RETURN QUERY SELECT FALSE, 'invalid_case', NULL::TEXT, 'Caso inválido. Use: lower o upper';
        RETURN;
    END IF;

    -- Si p_convertir es TRUE, retorna el string convertido
    IF p_convertir THEN
        RETURN QUERY SELECT TRUE, 'converted', v_result::TEXT, 'String convertido a ' || p_case;
    ELSE
        -- Si no convierte, verifica si ya está en el caso especificado
        IF (p_case = 'lower' AND p_string = LOWER(p_string)) OR 
           (p_case = 'upper' AND p_string = UPPER(p_string)) THEN
            RETURN QUERY SELECT TRUE, 'valid', p_string::TEXT, 'String ya está en ' || p_case;
        ELSE
            RETURN QUERY SELECT FALSE, 'needs_conversion', v_result::TEXT, 'String necesita conversión a ' || p_case;
        END IF;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Wrapper: Retorna solo BOOLEAN
-- is_mayus(p_string, 'lower') -> TRUE si ya es lowercase
-- is_mayus(p_string, 'upper') -> TRUE si ya es uppercase
-- ============================================================

DROP FUNCTION IF EXISTS is_case_standardized(TEXT, TEXT);

CREATE OR REPLACE FUNCTION is_case_standardized(
    p_string TEXT,
    p_case TEXT DEFAULT 'lower'
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_case = 'lower' THEN
        RETURN p_string = LOWER(p_string);
    ELSIF p_case = 'upper' THEN
        RETURN p_string = UPPER(p_string);
    END IF;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;