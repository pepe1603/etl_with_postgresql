# GUIA ETL - Ejercicio Práctico

## Descripción

Este paquete contiene scripts SQL para procesos ETL (Extract, Transform, Load) y los datos de prueba para practicar.

---

## Estructura de Archivos

```
carpeta/
├── GUIA.md              -- Este archivo
├── data/
│   ├── ventas_t.csv       -- 50,300 filas
│   ├── productos_t.csv   -- 50,300 filas
│   ├── sucursales_t.csv  -- 50,300 filas
│   ├── clientes_t.csv    -- 50,300 filas
│   └── detalleventas_t.csv -- 50,300 filas
└── scripts/
    ├── validate_date.sql     -- Funciones de validación de fechas
    ├── import_csv.sql        -- Funciones de importación CSV
    └── standardize_column.sql -- Funciones de estandarización
```

---

## Requisitos

- PostgreSQL 14 o superior instalado
- Servicio de PostgreSQL ejecutándose
- Usuario con permisos de creación de funciones

---

## Instrucciones de Ejecución

### Fase 1: Configuración Inicial

#### 1. Conectar a PostgreSQL

```bash
# Desde Docker
docker exec -it postgres17 psql -U usr_postgres -d postgres

# O localmente
psql -U tu_usuario -d postgres
```

#### 2. Crear base de datos

```sql
CREATE DATABASE ejercicio_etl_db;
```

#### 3. Instalar funciones ETL

```bash
# Ejecutar los scripts en orden
psql -U tu_usuario -d ejercicio_etl_db -f scripts/validate_date.sql
psql -U tu_usuario -d ejercicio_etl_db -f scripts/import_csv.sql
psql -U tu_usuario -d ejercicio_etl_db -f scripts/standardize_column.sql
```

---

### Fase 2: Importar Datos CSV

#### Copiar archivos al contenedor (Docker)

```bash
docker cp "ruta/data/ventas_t.csv" postgres17:/tmp/ventas_t.csv
docker cp "ruta/data/productos_t.csv" postgres17:/tmp/productos_t.csv
docker cp "ruta/data/sucursales_t.csv" postgres17:/tmp/sucursales_t.csv
docker cp "ruta/data/clientes_t.csv" postgres17:/tmp/clientes_t.csv
docker cp "ruta/data/detalleventas_t.csv" postgres17:/tmp/detalleventas_t.csv
```

#### Importar a PostgreSQL

```sql
-- Conectar a la base de datos
\c ejercicio_etl_db

-- Importar ventas (15 columnas)
SELECT * FROM import_csv_with_headers(
    '/tmp/ventas_t.csv',
    'ventas',
    ARRAY['id_venta','producto','categoria','marca','cliente','genero','edad','ciudad_cliente','sucursal','ciudad_sucursal','estado','fecha','cantidad','precio','total']
);

-- Importar productos (3 columnas)
SELECT * FROM import_csv_with_headers('/tmp/productos_t.csv', 'productos', ARRAY['producto', 'categoria', 'marca']);

-- Importar sucursales (3 columnas)
SELECT * FROM import_csv_with_headers('/tmp/sucursales_t.csv', 'sucursales', ARRAY['sucursal', 'ciudad_sucursal', 'estado']);

-- Importar clientes (4 columnas)
SELECT * FROM import_csv_with_headers('/tmp/clientes_t.csv', 'clientes', ARRAY['cliente', 'genero', 'edad', 'ciudad_cliente']);

-- Importar detalle_ventas (7 columnas)
SELECT * FROM import_csv_with_headers('/tmp/detalleventas_t.csv', 'detalle_ventas', ARRAY['id_venta', 'producto', 'cliente', 'sucursal', 'fecha', 'cantidad', 'precio']);
```

---

### Fase 3: Limpieza de Datos

#### Verificar y eliminar nulls/vacíos

```sql
-- Verificar nulls en cada tabla
SELECT COUNT(*) FROM ventas WHERE producto IS NULL OR producto = '';
SELECT COUNT(*) FROM clientes WHERE cliente IS NULL OR cliente = '';

-- Eliminar filas con nulls/vacíos
DELETE FROM ventas WHERE producto IS NULL OR producto = '';
DELETE FROM clientes WHERE cliente IS NULL OR cliente = '';

-- Verificar fechas futuras
SELECT COUNT(*) FROM ventas WHERE fecha > '2024-12-31';
```

---

### Fase 4: Análisis de Datos

#### Verificar datos importados

```sql
-- Contar filas por tabla
SELECT 'ventas' as tabla, COUNT(*) FROM ventas
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'sucursales', COUNT(*) FROM sucursales
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'detalle_ventas', COUNT(*) FROM detalle_ventas;
```

#### Análisis de ventas

```sql
-- Ventas por categoría
SELECT categoria, COUNT(*) as ventas, SUM(total::INT) as total
FROM ventas GROUP BY categoria ORDER BY total DESC;

-- Top 10 productos
SELECT producto, COUNT(*) as veces, SUM(total::INT) as total
FROM ventas GROUP BY producto ORDER BY total DESC LIMIT 10;

-- Por ciudad
SELECT ciudad_sucursal, COUNT(*) as ventas, SUM(total::INT) as total
FROM ventas GROUP BY ciudad_sucursal ORDER BY total DESC;

-- Por género
SELECT genero, COUNT(*) as ventas, SUM(total::INT) as total
FROM ventas GROUP BY genero;

-- Estandarizar ciudades (a minúsculas)
UPDATE ventas SET ciudad_sucursal = LOWER(ciudad_sucursal);
UPDATE ventas SET ciudad_cliente = LOWER(ciudad_cliente);
UPDATE ventas SET estado = LOWER(estado);
```

---

## Funciones Disponibles

### validate_date.sql

```sql
-- Validar fecha
SELECT * FROM validate_date('2024-01-15');

-- Validar con rango
SELECT * FROM validate_date('2024-06-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Rechazar fechas futuras
SELECT * FROM validate_date('2030-01-01', NULL, NULL, NULL, TRUE);

-- Wrapper booleano
SELECT is_valid_date('2024-01-15');
```

### import_csv.sql

```sql
-- Importar con headers
SELECT * FROM import_csv_with_headers(
    '/ruta/archivo.csv',
    'nombre_tabla',
    ARRAY['col1', 'col2', 'col3']
);

-- Append a tabla existente
SELECT * FROM append_csv_to_table('/ruta/archivo.csv', 'tabla_existente');
```

### standardize_column.sql

```sql
-- Verificar si string está en minúsculas
SELECT * FROM standardize_string_mayus_minus('Mérida', 'lower', FALSE);

-- Convertir a minúsculas
SELECT * FROM standardize_string_mayus_minus('MÉRIDA', 'lower', TRUE);

-- Wrapper booleano
SELECT is_case_standardized('mérida', 'lower');
```

---

## Resultados Esperados

| Tabla | Filas Inicial | Filas Final |
|-------|--------------|------------|
| ventas | 50,300 | 49,899 |
| productos | 50,300 | 50,300 |
| sucursales | 50,300 | 50,300 |
| clientes | 50,300 | 49,899 |
| detalle_ventas | 50,300 | 50,099 |

---

## Errores Comunes

### "permission denied"
Solución: Verificar permisos del archivo y carpeta

### "could not open file"
Solución: Verificar que la ruta es correcta

### "does not exist"
Solución: Verificar que PostgreSQL está corriendo

### "function does not exist"
Solución: Ejecutar los scripts de instalación nuevamente

---

## Soporte

Si tienes problemas:

1. Verifica que PostgreSQL está corriendo
2. Verifica que las rutas de archivos son correctas
3. Verifica los permisos de archivos
4. Ejecuta los scripts de instalación en orden

---

**Autor:** Ejercicio ETL
**Fecha:** 2026