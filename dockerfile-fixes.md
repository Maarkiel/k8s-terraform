# Poprawki do Dockerfile - rozwiązanie problemu z gunicorn PATH

## Problem
Gunicorn jest zainstalowany, ale Kubernetes nie może go znaleźć z powodu problemów z PATH.

## 🔧 ROZWIĄZANIE 1: Napraw PATH w Dockerfile

**Obecny Dockerfile prawdopodobnie ma:**
```dockerfile
ENV PATH=/home/appuser/.local/bin:$PATH
```

**Ale może być problem z kolejnością. Zmień na:**
```dockerfile
# Dodaj przed USER appuser
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Lub dodaj po USER appuser
USER appuser
ENV PATH="/home/appuser/.local/bin:${PATH}"
```

## 🔧 ROZWIĄZANIE 2: Użyj pełnej ścieżki w CMD

**Zmień CMD z:**
```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
```

**Na:**
```dockerfile
CMD ["/home/appuser/.local/bin/gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
```

## 🔧 ROZWIĄZANIE 3: Użyj python -m gunicorn

**Zmień CMD na:**
```dockerfile
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
```

## 🔧 ROZWIĄZANIE 4: Kompletny poprawiony Dockerfile

```dockerfile
# Multi-stage build dla optymalizacji
FROM python:3.11-slim as builder

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie pliku requirements
COPY app/requirements.txt .

# Instalacja zależności
RUN pip install --no-cache-dir --user -r requirements.txt

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
COPY --from=builder /root/.local /home/appuser/.local

# Kopiowanie kodu aplikacji
COPY app/ .

# Zmiana właściciela plików
RUN chown -R appuser:appuser /app

# Przełączenie na użytkownika bez uprawnień root
USER appuser

# POPRAWKA: Dodanie ścieżki do PATH AFTER switching user
ENV PATH="/home/appuser/.local/bin:${PATH}"

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

# POPRAWKA: Użyj python -m gunicorn zamiast bezpośredniego gunicorn
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
```

## 🚀 SKRYPT AUTOMATYCZNEJ NAPRAWY

```bash
#!/bin/bash
echo "🔧 NAPRAWIANIE DOCKERFILE"

# Backup original
cp docker/Dockerfile docker/Dockerfile.backup

# Create fixed Dockerfile
cat > docker/Dockerfile << 'EOF'
# Multi-stage build dla optymalizacji
FROM python:3.11-slim as builder

WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim

LABEL maintainer="Portfolio Demo"
LABEL description="K8s + Terraform Portfolio Demo Application"
LABEL version="1.0.0"

RUN groupadd -r appuser && useradd -r -g appuser appuser
WORKDIR /app

COPY --from=builder /root/.local /home/appuser/.local
COPY app/ .
RUN chown -R appuser:appuser /app

USER appuser

# FIXED: Add PATH after switching user
ENV PATH="/home/appuser/.local/bin:${PATH}"
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONPATH=/app
ENV PORT=5000

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# FIXED: Use python -m gunicorn
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
EOF

echo "✅ Dockerfile naprawiony!"
echo "Backup zapisany jako docker/Dockerfile.backup"
```

## 📋 KROKI NAPRAWY

1. **Zdiagnozuj problem** (uruchom quick-diagnosis.sh)
2. **Napraw Dockerfile** (użyj jednego z rozwiązań powyżej)
3. **Przebuduj obraz w minikube**
4. **Wdróż ponownie**

```bash
# 1. Napraw Dockerfile (wybierz metodę)
# 2. Przebuduj
eval $(minikube docker-env)
docker rmi portfolio-demo:latest
docker build -t portfolio-demo:latest -f docker/Dockerfile . --no-cache

# 3. Test
docker run --rm portfolio-demo:latest python -m gunicorn --version

# 4. Wdróż
eval $(minikube docker-env -u)
kubectl delete deployment portfolio-app -n portfolio-demo
kubectl apply -f k8s/deployment.yaml
```

