from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
import os
import datetime
import socket

app = Flask(__name__)
CORS(app)

# Konfiguracja z zmiennych środowiskowych
app.config['APP_NAME'] = os.getenv('APP_NAME', 'K8s-Terraform Portfolio Demo')
app.config['APP_VERSION'] = os.getenv('APP_VERSION', '1.0.0')
app.config['ENVIRONMENT'] = os.getenv('ENVIRONMENT', 'development')

# Mock data dla demonstracji
TASKS = [
    {"id": 1, "title": "Setup Kubernetes cluster", "status": "completed", "priority": "high"},
    {"id": 2, "title": "Configure Terraform", "status": "completed", "priority": "high"},
    {"id": 3, "title": "Deploy application", "status": "in-progress", "priority": "medium"},
    {"id": 4, "title": "Setup monitoring", "status": "pending", "priority": "low"},
    {"id": 5, "title": "Configure CI/CD", "status": "pending", "priority": "medium"}
]

@app.route('/')
def index():
    """Strona główna aplikacji"""
    return render_template('index.html', 
                         app_name=app.config['APP_NAME'],
                         version=app.config['APP_VERSION'],
                         environment=app.config['ENVIRONMENT'])

@app.route('/health')
def health_check():
    """Health check endpoint dla Kubernetes"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.datetime.now().isoformat(),
        "hostname": socket.gethostname(),
        "version": app.config['APP_VERSION']
    })

@app.route('/api/status')
def api_status():
    """API endpoint zwracający status aplikacji"""
    return jsonify({
        "app_name": app.config['APP_NAME'],
        "version": app.config['APP_VERSION'],
        "environment": app.config['ENVIRONMENT'],
        "hostname": socket.gethostname(),
        "timestamp": datetime.datetime.now().isoformat(),
        "uptime": "Running in container"
    })

@app.route('/api/tasks')
def get_tasks():
    """API endpoint zwracający listę zadań"""
    status_filter = request.args.get('status')
    if status_filter:
        filtered_tasks = [task for task in TASKS if task['status'] == status_filter]
        return jsonify({"tasks": filtered_tasks, "count": len(filtered_tasks)})
    return jsonify({"tasks": TASKS, "count": len(TASKS)})

@app.route('/api/tasks/<int:task_id>')
def get_task(task_id):
    """API endpoint zwracający konkretne zadanie"""
    task = next((task for task in TASKS if task['id'] == task_id), None)
    if task:
        return jsonify(task)
    return jsonify({"error": "Task not found"}), 404

@app.route('/api/info')
def app_info():
    """Endpoint z informacjami o środowisku"""
    return jsonify({
        "kubernetes": {
            "namespace": os.getenv('KUBERNETES_NAMESPACE', 'default'),
            "pod_name": os.getenv('HOSTNAME', 'unknown'),
            "service_account": os.getenv('KUBERNETES_SERVICE_ACCOUNT', 'default')
        },
        "container": {
            "hostname": socket.gethostname(),
            "environment": app.config['ENVIRONMENT']
        },
        "application": {
            "name": app.config['APP_NAME'],
            "version": app.config['APP_VERSION']
        }
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=port, debug=debug)

