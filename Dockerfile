# Utiliza una imagen oficial de Python como base
FROM python:3.10-slim

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos necesarios
COPY requirements.txt ./
COPY validador.py ./
COPY .env ./
COPY credentials.json ./

# Instala las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Expone el puerto que usará Flask/Gunicorn
EXPOSE 8080

# Comando para ejecutar la app con Gunicorn en Cloud Run
CMD exec gunicorn --bind :8080 --workers 1 --threads 8 validador:app 