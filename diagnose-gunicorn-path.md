# Diagnoza problemu z gunicorn - obraz ma gunicorn ale K8s go nie znajduje

## Sytuacja
- Obraz Docker lokalnie ma gunicorn: ✅ `gunicorn 21.2.0`
- Kubernetes pokazuje błąd: ❌ `No module named 'gunicorn'`

## Możliwe przyczyny

### 1. Kubernetes używa innego obrazu
Kubernetes może używać obrazu z Docker Hub zamiast lokalnego obrazu.

### 2. Problem z PATH
Gunicorn jest zainstalowany w `/home/appuser/.local/bin/` ale PATH może nie zawierać tej ścieżki.

### 3. Problem z użytkownikiem
Kontener może uruchamiać się jako inny użytkownik niż `appuser`.

### 4. Problem z imagePullPolicy
Kubernetes może próbować pobrać obraz z internetu zamiast używać lokalnego.

## 🔍 KOMENDY DIAGNOSTYCZNE

### Sprawdź obraz w minikube
```bash
eval $(minikube docker-env)
docker images | grep portfolio-demo
```

### Sprawdź PATH w obrazie
```bash
docker run --rm portfolio-demo:latest echo $PATH
```

### Sprawdź lokalizację gunicorn
```bash
docker run --rm portfolio-demo:latest which gunicorn
docker run --rm portfolio-demo:latest ls -la /home/appuser/.local/bin/gunicorn
```

### Sprawdź użytkownika
```bash
docker run --rm portfolio-demo:latest whoami
docker run --rm portfolio-demo:latest id
```

### Sprawdź zmienne środowiskowe
```bash
docker run --rm portfolio-demo:latest env | grep PATH
```

### Sprawdź czy gunicorn jest wykonywalny
```bash
docker run --rm portfolio-demo:latest ls -la /home/appuser/.local/bin/
```

## 🔧 MOŻLIWE ROZWIĄZANIA

### Rozwiązanie 1: Napraw PATH w Dockerfile
Dodaj do Dockerfile przed CMD:
```dockerfile
ENV PATH=/home/appuser/.local/bin:$PATH
```

### Rozwiązanie 2: Użyj pełnej ścieżki w CMD
Zmień CMD w Dockerfile:
```dockerfile
CMD ["/home/appuser/.local/bin/gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
```

### Rozwiązanie 3: Sprawdź imagePullPolicy
W deployment.yaml upewnij się, że masz:
```yaml
imagePullPolicy: Never  # Dla lokalnych obrazów
```

### Rozwiązanie 4: Użyj python -m gunicorn
Zmień CMD w Dockerfile:
```dockerfile
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
```

### Rozwiązanie 5: Debuguj kontener w Kubernetes
```bash
# Uruchom kontener z bash do debugowania
kubectl run debug-pod --image=portfolio-demo:latest --rm -it -- /bin/bash

# W kontenerze sprawdź:
whoami
echo $PATH
which gunicorn
pip list | grep gunicorn
```

## 🚀 SZYBKI TEST ROZWIĄZAŃ

### Test 1: Sprawdź czy problem jest z PATH
```bash
docker run --rm portfolio-demo:latest /home/appuser/.local/bin/gunicorn --version
```

### Test 2: Sprawdź czy python -m gunicorn działa
```bash
docker run --rm portfolio-demo:latest python -m gunicorn --version
```

### Test 3: Sprawdź czy PATH jest poprawny
```bash
docker run --rm portfolio-demo:latest bash -c "export PATH=/home/appuser/.local/bin:\$PATH && gunicorn --version"
```

## 📋 PLAN NAPRAWY

1. **Uruchom komendy diagnostyczne** powyżej
2. **Zidentyfikuj przyczynę** (PATH, użytkownik, obraz)
3. **Zastosuj odpowiednie rozwiązanie**
4. **Przebuduj obraz** w minikube
5. **Wdróż ponownie** aplikację
6. **Sprawdź logi** Kubernetes

## 🔄 KOMPLETNY SKRYPT NAPRAWCZY

```bash
#!/bin/bash
echo "=== DIAGNOZA I NAPRAWA PROBLEMU Z GUNICORN ==="

# 1. Sprawdź obraz w minikube
eval $(minikube docker-env)
echo "Obrazy w minikube:"
docker images | grep portfolio-demo

# 2. Sprawdź PATH i gunicorn
echo "PATH w obrazie:"
docker run --rm portfolio-demo:latest echo $PATH

echo "Lokalizacja gunicorn:"
docker run --rm portfolio-demo:latest which gunicorn || echo "gunicorn nie znaleziony w PATH"

echo "Sprawdzenie pełnej ścieżki:"
docker run --rm portfolio-demo:latest ls -la /home/appuser/.local/bin/gunicorn

# 3. Test różnych sposobów uruchomienia
echo "Test pełnej ścieżki:"
docker run --rm portfolio-demo:latest /home/appuser/.local/bin/gunicorn --version

echo "Test python -m gunicorn:"
docker run --rm portfolio-demo:latest python -m gunicorn --version

# 4. Napraw Dockerfile i przebuduj
echo "Naprawianie Dockerfile..."
# Tutaj można dodać automatyczne poprawki

eval $(minikube docker-env -u)
```

