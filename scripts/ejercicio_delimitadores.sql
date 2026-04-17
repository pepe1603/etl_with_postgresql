-- ==========================================
-- Ejercicio delimitadores 
-- Semana 2 - Ejercicios COPY
-- ==========================================

-- Conectar a la base de datos
\c ejercicio_delimitadores

-- ==========================================
-- PARTE 1: Crear tabla estudiante
-- ==========================================
DROP TABLE IF EXISTS estudiante CASCADE;

CREATE TABLE estudiante (
    matricula INT PRIMARY KEY, 
    nombre TEXT, 
    edad INT
);

-- ==========================================
-- PARTE 2: Insertar datos iniciales
-- ==========================================
INSERT INTO estudiante VALUES 
(1,'a',10),
(2,'b',15),
(3,'c',20);

-- Ver datos
SELECT * FROM estudiante;

-- ==========================================
-- PARTE 3: Exportar a archivo CSV (delimitador coma)
-- ==========================================
COPY estudiante TO '/Users/pepe_gope/Desktop/seminario_Programacion/modulo4/sem2/ejercicios/datos/estudiante_coma.csv' WITH (FORMAT CSV, HEADER);

-- ==========================================
-- PARTE 4: Insertar dato con coma en el nombre (problema)
-- ==========================================
INSERT INTO estudiante VALUES (4,'tapachula, chiapas',25);

-- ==========================================
-- PARTE 5: Exportar con delimitadores diferentes
-- ==========================================
-- Exportar con coma (CSV) - las comas dentro de campos se encierran en comillas
COPY estudiante TO '/Users/pepe_gope/Desktop/seminario_Programacion/modulo4/sem2/ejercicios/datos/estudiante_coma_problema.csv' WITH (FORMAT CSV, HEADER);

-- Exportar con punto y coma
COPY estudiante TO '/Users/pepe_gope/Desktop/seminario_Programacion/modulo4/sem2/ejercicios/datos/estudiante_punto_coma.csv' WITH (FORMAT CSV, HEADER);

-- ==========================================
-- PARTE 6: Crear tablas para importar y verificar
-- ==========================================
DROP TABLE IF EXISTS estudiante_coma;
DROP TABLE IF EXISTS estudiante_pcomas;

CREATE TABLE estudiante_coma (matricula INT PRIMARY KEY, nombre TEXT, edad INT);
CREATE TABLE estudiante_pcomas (matricula INT PRIMARY KEY, nombre TEXT, edad INT);

-- ==========================================
-- PARTE 7: Importar desde archivos
-- ==========================================
COPY estudiante_coma FROM '/Users/pepe_gope/Desktop/seminario_Programacion/modulo4/sem2/ejercicios/datos/estudiante_coma_problema.csv' WITH (FORMAT CSV, HEADER);
COPY estudiante_pcomas FROM '/Users/pepe_gope/Desktop/seminario_Programacion/modulo4/sem2/ejercicios/datos/estudiante_punto_coma.csv' WITH (FORMAT CSV, HEADER);

-- ==========================================
-- PARTE 8: Verificar importación
-- ==========================================
SELECT 'Estudiante original (coma)' as fuente, * FROM estudiante
UNION ALL
SELECT 'Importado desde archivo csv', * FROM estudiante_coma
ORDER BY matricula;

-- Nota Resultado: Los datos con coma se importaron correctamente
-- porque CSV maneja campos con comas encerrándolos en comillas dobles