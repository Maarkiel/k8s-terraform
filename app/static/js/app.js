// Główna aplikacja JavaScript
class PortfolioApp {
    constructor() {
        this.currentFilter = 'all';
        this.init();
    }

    init() {
        this.loadAppStatus();
        this.loadTasks();
        this.loadEnvironmentInfo();
        this.setupEventListeners();
        
        // Odświeżanie co 30 sekund
        setInterval(() => {
            this.loadAppStatus();
        }, 30000);
    }

    setupEventListeners() {
        // Filtry zadań
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.setActiveFilter(e.target);
                this.currentFilter = e.target.dataset.status;
                this.loadTasks();
            });
        });
    }

    setActiveFilter(activeBtn) {
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        activeBtn.classList.add('active');
    }

    async loadAppStatus() {
        try {
            const response = await fetch('/api/status');
            const data = await response.json();
            this.renderAppStatus(data);
        } catch (error) {
            console.error('Błąd ładowania statusu:', error);
            this.renderError('app-status', 'Błąd ładowania statusu aplikacji');
        }
    }

    async loadTasks() {
        try {
            const url = this.currentFilter === 'all' 
                ? '/api/tasks' 
                : `/api/tasks?status=${this.currentFilter}`;
            
            const response = await fetch(url);
            const data = await response.json();
            this.renderTasks(data.tasks);
        } catch (error) {
            console.error('Błąd ładowania zadań:', error);
            this.renderError('tasks-list', 'Błąd ładowania zadań');
        }
    }

    async loadEnvironmentInfo() {
        try {
            const response = await fetch('/api/info');
            const data = await response.json();
            this.renderEnvironmentInfo(data);
        } catch (error) {
            console.error('Błąd ładowania informacji środowiska:', error);
            this.renderError('env-info', 'Błąd ładowania informacji środowiska');
        }
    }

    renderAppStatus(data) {
        const container = document.getElementById('app-status');
        container.innerHTML = `
            <div class="status-info">
                <div class="status-item">
                    <span class="status-label"><i class="fas fa-server"></i> Hostname</span>
                    <span class="status-value">${data.hostname}</span>
                </div>
                <div class="status-item">
                    <span class="status-label"><i class="fas fa-tag"></i> Wersja</span>
                    <span class="status-value">${data.version}</span>
                </div>
                <div class="status-item">
                    <span class="status-label"><i class="fas fa-cog"></i> Środowisko</span>
                    <span class="status-value">${data.environment}</span>
                </div>
                <div class="status-item">
                    <span class="status-label"><i class="fas fa-clock"></i> Ostatnia aktualizacja</span>
                    <span class="status-value">${this.formatTimestamp(data.timestamp)}</span>
                </div>
            </div>
        `;
    }

    renderTasks(tasks) {
        const container = document.getElementById('tasks-list');
        
        if (tasks.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; padding: 20px; color: #666;">
                    <i class="fas fa-inbox"></i> Brak zadań dla wybranego filtra
                </div>
            `;
            return;
        }

        container.innerHTML = tasks.map(task => `
            <div class="task-item ${task.status}">
                <div class="task-info">
                    <div class="task-title">${task.title}</div>
                    <div class="task-meta">
                        <span class="task-status ${task.status}">${this.getStatusText(task.status)}</span>
                        <span class="task-priority ${task.priority}">
                            <i class="fas fa-flag"></i> ${this.getPriorityText(task.priority)}
                        </span>
                    </div>
                </div>
                <div class="task-id">#${task.id}</div>
            </div>
        `).join('');
    }

    renderEnvironmentInfo(data) {
        const container = document.getElementById('env-info');
        container.innerHTML = `
            <div class="env-section">
                <h4><i class="fas fa-dharmachakra"></i> Kubernetes</h4>
                <div class="env-item">
                    <span class="env-key">Namespace</span>
                    <span class="env-value">${data.kubernetes.namespace}</span>
                </div>
                <div class="env-item">
                    <span class="env-key">Pod Name</span>
                    <span class="env-value">${data.kubernetes.pod_name}</span>
                </div>
                <div class="env-item">
                    <span class="env-key">Service Account</span>
                    <span class="env-value">${data.kubernetes.service_account}</span>
                </div>
            </div>
            
            <div class="env-section">
                <h4><i class="fab fa-docker"></i> Container</h4>
                <div class="env-item">
                    <span class="env-key">Hostname</span>
                    <span class="env-value">${data.container.hostname}</span>
                </div>
                <div class="env-item">
                    <span class="env-key">Environment</span>
                    <span class="env-value">${data.container.environment}</span>
                </div>
            </div>
            
            <div class="env-section">
                <h4><i class="fas fa-cube"></i> Application</h4>
                <div class="env-item">
                    <span class="env-key">Name</span>
                    <span class="env-value">${data.application.name}</span>
                </div>
                <div class="env-item">
                    <span class="env-key">Version</span>
                    <span class="env-value">${data.application.version}</span>
                </div>
            </div>
        `;
    }

    renderError(containerId, message) {
        const container = document.getElementById(containerId);
        container.innerHTML = `
            <div style="text-align: center; padding: 20px; color: #dc3545;">
                <i class="fas fa-exclamation-triangle"></i> ${message}
            </div>
        `;
    }

    getStatusText(status) {
        const statusMap = {
            'completed': 'Ukończone',
            'in-progress': 'W trakcie',
            'pending': 'Oczekujące'
        };
        return statusMap[status] || status;
    }

    getPriorityText(priority) {
        const priorityMap = {
            'high': 'Wysoki',
            'medium': 'Średni',
            'low': 'Niski'
        };
        return priorityMap[priority] || priority;
    }

    formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        return date.toLocaleString('pl-PL', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
    }
}

// Inicjalizacja aplikacji po załadowaniu DOM
document.addEventListener('DOMContentLoaded', () => {
    new PortfolioApp();
});

// Dodatkowe funkcje pomocnicze
window.testEndpoint = async function(endpoint) {
    try {
        const response = await fetch(endpoint);
        const data = await response.json();
        console.log(`Response from ${endpoint}:`, data);
        alert(`Sprawdź konsolę dla odpowiedzi z ${endpoint}`);
    } catch (error) {
        console.error(`Error testing ${endpoint}:`, error);
        alert(`Błąd podczas testowania ${endpoint}: ${error.message}`);
    }
};

// Funkcja do testowania wszystkich endpointów
window.testAllEndpoints = async function() {
    const endpoints = ['/health', '/api/status', '/api/tasks', '/api/info'];
    
    console.log('=== Testing All Endpoints ===');
    
    for (const endpoint of endpoints) {
        try {
            const response = await fetch(endpoint);
            const data = await response.json();
            console.log(`✅ ${endpoint}:`, data);
        } catch (error) {
            console.error(`❌ ${endpoint}:`, error);
        }
    }
    
    alert('Sprawdź konsolę dla wyników testów wszystkich endpointów');
};

