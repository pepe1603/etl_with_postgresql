# Fase 1: Configuración PostgreSQL

## Objetivos
- [x] Crear repositorio git
- [x] Configurar ramas (main, feat-fase-1)
- [x] Conectar a PostgreSQL en Docker
- [x] Crear base de datos `ejercicio_etl_db`
- [x] Instalar funciones ETL

## Comandos ejecutados

### Git
```bash
git init
git checkout -b main
git add . && git commit -m "Initial commit"
git checkout -b feat-fase-1
```

### PostgreSQL
```bash
# Crear base de datos
docker exec postgres17 psql -U usr_postgres -d postgres -c "CREATE DATABASE ejercicio_etl_db;"

# Instalar funciones
docker exec -i postgres17 psql -U usr_postgres -d ejercicio_etl_db < scripts/validate_date.sql
docker exec -i postgres17 psql -U usr_postgres -d ejercicio_etl_db < scripts/import_csv.sql
docker exec -i postgres17 psql -U usr_postgres -d ejercicio_etl_db < scripts/standardize_column.sql
```

## Funciones instaladas

### validate_date.sql
- `validate_date()` - Valida fechas con formato, rango, rechaza fechas futuras
- `is_valid_date()` - Wrapper booleano

### import_csv.sql
- `import_csv_to_table()` - Importa CSV con columnas genéricas
- `import_csv_with_headers()` - Importa CSV con headers personalizados
- `append_csv_to_table()` - Agrega datos a tabla existente

### standardize_column.sql
- `standardize_string_mayus_minus()` - Estandariza/verifica caso de string
- `is_case_standardized()` - Wrapper booleano

## Pruebas realizadas
| Función | Prueba | Resultado |
|---------|--------|-----------|
| `validate_date('2024-01-15')` | Fecha válida | ✓ válido |
| `validate_date('invalid-date')` | Formato inválido | ✓ rechazado |
| `validate_date('2030-01-01',...,TRUE)` | Fecha futura | ✓ rechazado |
| `import_csv_with_headers()` | Importar CSV | ✓ dinámico |
| `standardize_string_mayus_minus()` | Estandarizar | ✓ funciona |

## Siguiente fase
Fase 2: Importar datos desde CSV a PostgreSQL