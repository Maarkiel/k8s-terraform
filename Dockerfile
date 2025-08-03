# Multi-stage build dla optymalizacji
FROM python:3.11-slim as builder

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie pliku requirements
COPY app/requirements.txt .

# Instalacja zależności
RUN pip install --no-cache-dir --prefix=/usr/local -r requirements.txt



# Główny obraz
FROM python:3.11-slim

# Metadane
LABEL maintainer="Portfolio Demo"
LABEL description="K8s + Terraform Portfolio Demo Application"
LABEL version="1.0.0"

# Tworzenie użytkownika bez uprawnień root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie zależności z builder stage
COPY --from=builder /usr/local /usr/local


# Kopiowanie kodu aplikacji
COPY app/ .

# Zmiana właściciela plików
RUN chown -R appuser:appuser /app

# Przełączenie na użytkownika bez uprawnień root
USER appuser

# FIXED: Dodanie ścieżki do PATH AFTER switching user
# ENV PATH="/home/appuser/.local/bin:${PATH}"

# Zmienne środowiskowe
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONPATH=/app
ENV PORT=5000

# Eksponowanie portu
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# FIXED: Użyj python -m gunicorn zamiast bezpośredniego gunicorn
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
