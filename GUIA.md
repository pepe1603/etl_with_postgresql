# GUIA ETL - Scripts de Importacion y Limpieza de CSV

## Descripcion

Este paquete contiene scripts SQL para procesos ETL (Extract, Transform, Load):
- **Validacion de fechas** - Valida formato y rango de fechas
- **Limpieza de CSV** - Elimina filas con nulos y fechas invalidas
- **Importacion de CSV** - Importa archivos CSV a PostgreSQL

---

## Requisitos

### 1. PostgreSQL
- PostgreSQL 14 o superior instalado
- Servicio de PostgreSQL ejecutandose

### 2. Base de datos
- Una base de datos donde crear las funciones
- Usuario con permisos de creacion de funciones

---

## Instalacion

### Paso 1: Crear las funciones en tu base de datos

Abre tu terminal y ejecuta:

```bash
# Conecta a tu base de datos
psql -U TU_USUARIO -d TU_BASE_DE_DATOS

# Ejecuta los scripts en este orden:
\i scripts/validate_date.sql
\i scripts/import_csv.sql
```

O desde terminal del sistema:

```bash
psql -U TU_USUARIO -d TU_BASE_DE_DATOS -f scripts/validate_date.sql
psql -U TU_USUARIO -d TU_BASE_DE_DATOS -f scripts/import_csv.sql
```

---

## Como Usar los Scripts

### 1. VALIDAR FECHAS

**Funcion: `validate_date()`**

Valida si una fecha es correcta.

```sql
-- Verificar si una fecha es valida
SELECT * FROM validate_date('2024-01-15');

-- Con rango de fechas
SELECT * FROM validate_date('2024-06-15', 'YYYY-MM-DD', '2024-01-01', '2024-12-31');

-- Rechazar fechas futuras
SELECT * FROM validate_date('2030-01-01', NULL, NULL, NULL, TRUE);

-- Simple booleano
SELECT is_valid_date('2024-01-15');
```

**Parametros:**
- `p_date` - La fecha a validar (texto)
- `p_format` - Formato esperado (default: YYYY-MM-DD)
- `p_min_date` - Fecha minima (opcional)
- `p_max_date` - Fecha maxima (opcional)
- `p_reject_future` - Rechazar fechas futuras (TRUE/FALSE)

**Retorna:**
- `is_valid` - TRUE/FALSE
- `status` - Estado (valid, invalid_format, below_minimum, exceeds_maximum, etc.)
- `parsed_date` - Fecha parseada
- `message` - Mensaje descriptivo

---

### 2. IMPORTAR CSV A POSTGRESQL

**Funcion: `import_csv_to_table()`**

Importa un archivo CSV creando tabla con columnas genericas.

```sql
SELECT * FROM import_csv_to_table(
    '/ruta/completa/archivo.csv',  -- Ruta del archivo
    'nombre_tabla',                -- Nombre de la tabla
    5                              -- Numero de columnas
);
```

**Funcion: `import_csv_with_headers()`**

Importa CSV con nombres de columnas personalizados.

```sql
SELECT * FROM import_csv_with_headers(
    '/ruta/completa/archivo.csv',
    'empleados',
    ARRAY['id', 'nombre', 'fecha_inicio', 'fecha_fin', 'estado']
);
```

**Funcion: `append_csv_to_table()`**

Agrega datos a una tabla existente.

```sql
SELECT * FROM append_csv_to_table(
    '/ruta/completa/archivo.csv',
    'tabla_existente'
);
```

---

### 3. LIMPIAR CSV (Script Interactivo)

El script `clean_csv.sql` limpia un archivo CSV eliminando:
- Filas con valores nulos
- Filas con fechas invalidas

**Uso:**

```bash
psql -U TU_USUARIO -d TU_BASE_DE_DATOS -v file='/ruta/archivo.csv' -f scripts/clean_csv.sql
```

**Ejemplo:**

```bash
psql -U pepe_gope -d postgres -v file='/Users/pepe/Desktop/datos.csv' -f scripts/clean_csv.sql
```

**El script:**
1. Lee el archivo CSV
2. Crea tabla temporal
3. Analiza y cuenta filas con problemas
4. Exporta archivo limpio (sobreescribe el original)
5. Muestra reporte de limpieza

---

## Ejemplo Completo de Uso

### 1. Preparar archivo de prueba

Crea un archivo `datos.csv`:

```csv
id,nombre,fecha_inicio,fecha_fin,estado
1,Juan,2024-01-15,2024-06-30,activo
2,Maria,invalid-date,2024-07-15,activo
3,Pedro,2024-02-20,,pendiente
4,Ana,2024-03-10,2024-08-31,activo
5,Luis,,2024-09-30,activo
```

### 2. Importar a PostgreSQL

```sql
SELECT * FROM import_csv_with_headers(
    '/Users/tu_usuario/Desktop/datos.csv',
    'empleados',
    ARRAY['id', 'nombre', 'fecha_inicio', 'fecha_fin', 'estado']
);
```

### 3. Verificar los datos

```sql
SELECT * FROM empleados;
```

### 4. Limpiar datos invalidos

```bash
psql -U tu_usuario -d postgres -v file='/Users/tu_usuario/Desktop/datos.csv' -f scripts/clean_csv.sql
```

---

## Errores Comunes

### "permission denied"
Solucion: Verificar permisos del archivo y carpeta

### "could not open file"
Solucion: Verificar que la ruta es correcta

### "does not exist"
Solucion: Verificar que PostgreSQL esta corriendo

### "function does not exist"
Solucion: Ejecutar los scripts de instalacion nuevamente

---

## Archivos Incluidos

```
etl_scripts/
├── GUIA_PARA_AMIGO.md    -- Este archivo
└── scripts/
    ├── validate_date.sql  -- Funciones de validacion
    ├── import_csv.sql     -- Funciones de importacion
    └── clean_csv.sql      -- Script de limpieza
```

---

## Configuracion de PostgreSQL

### Iniciar PostgreSQL (Mac con Homebrew)

```bash
brew services start postgresql@14
```

### Conectar a PostgreSQL

```bash
psql -U TU_USUARIO -d TU_BASE_DE_DATOS
```

### Ver bases de datos disponibles

```sql
\l
```

### Ver tablas

```sql
\dt
```

---

## Credenciales

Configura tu conexion editando los comandos segun tu configuracion:

```bash
# Formato
psql -U USUARIO -d BASE_DE_DATOS

# Ejemplo
psql -U postgres -d postgres
psql -U mi_usuario -d mi_base
```

---

## Fase 1: Configuración PostgreSQL

### Base de datos
- Nombre: `ejercicio_etl_db`
- Usuario: `usr_postgres`

### Funciones instaladas

#### validate_date.sql
- `validate_date()` - Valida fechas con formato, rango, rechaza fechas futuras
- `is_valid_date()` - Wrapper booleano

#### import_csv.sql
- `import_csv_to_table()` - Importa CSV con columnas genéricas
- `import_csv_with_headers()` - Importa CSV con headers personalizados
- `append_csv_to_table()` - Agrega datos a tabla existente

#### standardize_column.sql
- `standardize_string_mayus_minus()` - Estandariza/verifica caso de string
- `is_case_standardized()` - Wrapper booleano

---

### Fase 2: Importar datos CSV

#### Archivos importados
| Tabla | Filas |
|-------|-------|
| productos | 50300 |
| sucursales | 50300 |
| clientes | 50300 |
| detalle_ventas | 50300 |
| ventas | 50300 |

---

## Versión

**v1.0.0** - Ejercicio ETL completo

## Repositorio Remoto

https://github.com/pepe1603/etl_with_postgresql.git

```bash
# Clonar
git clone https://github.com/pepe1603/etl_with_postgresql.git

# Ver versión
git checkout v1.0.0
```

---

**Fecha de creacion:** 2024
**Autor:** Ejercicio ETL
