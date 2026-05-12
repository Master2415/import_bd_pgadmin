import pandas as pd
# pyrefly: ignore [missing-import]
from sqlalchemy import create_engine
import os
import time
import psycopg2
import sys

# =================================================================
# CONFIGURACIÓN DE LA BASE DE DATOS
# =================================================================
DB_USER = "root"
DB_PASS = "ROOT"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "cruceunidades_2025"

def log(msg):
    """
    Imprime un mensaje en la consola con la marca de tiempo actual.
    """
    print(f"[{time.strftime('%H:%M:%S')}] {msg}")
    sys.stdout.flush()

def verify_connection():
    """
    Verifica la conexión a la base de datos existente.
    No intenta crearla, solo validar que podemos entrar con 'postgres' o 'root'.
    """
    log(f"Intentando conectar a la base de datos '{DB_NAME}'...")
    
    # Intentamos con los usuarios configurados
    for user in ["postgres", "root"]:
        try:
            conn = psycopg2.connect(
                dbname=DB_NAME, 
                user=user, 
                password=DB_PASS, 
                host=DB_HOST, 
                port=DB_PORT
            )
            conn.close()
            return user  # Retorna el usuario que funcionó
        except Exception:
            continue
            
    log("Error: No se pudo conectar a PostgreSQL. Asegúrate de que la BD exista y el servicio esté corriendo.")
    return None

def migrate(file_path, target_sheet, custom_table_name):
    """
    Gestiona el proceso de migración de una hoja específica a una tabla con nombre personalizado.
    """
    # 1. Limpiar ruta de posibles comillas
    file_path = file_path.strip().strip('"').strip("'")
    
    # 2. Verificar existencia del archivo
    if not os.path.exists(file_path):
        log(f"Error: El archivo no existe en la ruta: {file_path}")
        return

    # 3. Verificar conexión a la BD
    user_ok = verify_connection()
    if not user_ok:
        return

    # 4. Configurar motor
    engine = create_engine(f"postgresql://{user_ok}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

    try:
        log(f"Abriendo archivo: {os.path.basename(file_path)}")
        with pd.ExcelFile(file_path) as xls:
            # Validar que la hoja exista
            if target_sheet not in xls.sheet_names:
                log(f"Error: La hoja '{target_sheet}' no se encuentra en el archivo.")
                log(f"Hojas disponibles: {xls.sheet_names}")
                return

            log(f"Leyendo datos de la hoja '{target_sheet}'...")
            start_time = time.time()
            df = pd.read_excel(xls, sheet_name=target_sheet)
            
            if len(df) == 0:
                log("La hoja seleccionada está vacía.")
                return

            # Normalizar nombres de columnas para evitar errores en Postgres
            log("Normalizando nombres de columnas...")
            df.columns = [
                str(col).strip().lower()
                .replace(" ", "_")
                .replace(".", "")
                .replace("(", "")
                .replace(")", "")
                .replace("/", "_")
                .replace("-", "_")
                for col in df.columns
            ]

            # Usar el nombre de tabla proporcionado por el usuario
            table_name = custom_table_name.strip().lower().replace(" ", "_")
            
            log(f"Importando {len(df)} filas a la tabla '{table_name}'...")
            
            # Exportación con reemplazo si la tabla ya existe
            df.to_sql(
                table_name, 
                engine, 
                if_exists='replace', 
                index=False, 
                chunksize=10000
            )
            
            duration = time.time() - start_time
            log(f"¡PROCESO COMPLETADO! Tabla '{table_name}' creada/actualizada en {duration:.2f}s")

    except Exception as e:
        log(f"Ocurrió un error inesperado: {e}")

if __name__ == "__main__":
    print("\n" + "="*50)
    print("   IMPORTADOR DE EXCEL A POSTGRESQL (TABLA PERSONALIZADA)   ")
    print("="*50)
    
    # Solicitar datos de forma secuencial
    ruta = input("\n1. Pega la ruta completa del archivo Excel: ").strip()
    
    if not ruta:
        print("Error: La ruta del archivo es obligatoria.")
        sys.exit()

    hoja = input("2. ¿Qué hoja quieres importar? (ej: BD): ").strip()
    if not hoja:
        print("Error: El nombre de la hoja es obligatorio.")
        sys.exit()

    tabla = input("3. ¿Qué nombre quieres darle a la TABLA en Postgres?: ").strip()
    if not tabla:
        print("Error: El nombre de la tabla es obligatorio.")
        sys.exit()

    # Ejecutar migración
    migrate(ruta, hoja, tabla)
