# Fase 1: Configuración PostgreSQL

## Objetivos
- [x] Crear repositorio git
- [x] Configurar ramas (main, feat-fase-1)
- [x] Conectar a PostgreSQL en Docker
- [x] Crear base de datos `ejercicio_etl_db`
- [x] Instalar funciones ETL (validate_date, import_csv)

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
```

## Funciones instaladas
- `validate_date()` - Valida fechas con soporte de rango
- `is_valid_date()` - Wrapper booleano simple
- `import_csv_to_table()` - Importa CSV con columnas genéricas
- `import_csv_with_headers()` - Importa CSV con headers personalizados
- `append_csv_to_table()` - Agrega datos a tabla existente

## Siguiente fase
Fase 2: Importar datos desde CSV a PostgreSQL