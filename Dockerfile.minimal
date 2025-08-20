FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias
RUN pip install --no-cache-dir fastapi uvicorn[standard]

# Copiar archivo Python
COPY simple.py /app/

# Exponer puerto
EXPOSE 8080

# Comando de inicio
CMD ["python", "simple.py"]