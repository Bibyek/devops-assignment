#!/usr/bin/env bash
#
# infra_health_check.sh
# Checks CPU, RAM, root disk usage, Docker status, and the web app container.
# Warns + logs if disk > 85% or the app container is not running.
#
set -euo pipefail

# ---- Config ----
DISK_THRESHOLD=85
APP_CONTAINER="node_app"
LOG_FILE="/var/log/infra_health.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# ---- Helpers ----
log_warning() {
    local message="$1"
    echo "[WARNING] ${message}"
    echo "${TIMESTAMP} [WARNING] ${message}" >> "${LOG_FILE}"
}

# ---- CPU usage (%) ----
CPU_USAGE=$(top -bn1 | grep -i "Cpu(s)" | awk '{print $2 + $4}')

# ---- RAM usage (%) ----
RAM_USAGE=$(free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}')

# ---- Root disk usage (%) ----
DISK_USAGE=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

# ---- Report resource utilization ----
echo "===== Infra Health Check: ${TIMESTAMP} ====="
echo "CPU Usage:   ${CPU_USAGE}%"
echo "RAM Usage:   ${RAM_USAGE}%"
echo "Disk Usage (/): ${DISK_USAGE}%"

# ---- Docker running? ----
if systemctl is-active --quiet docker; then
    echo "Docker:      running"
    DOCKER_OK=true
else
    echo "Docker:      NOT running"
    DOCKER_OK=false
    log_warning "Docker service is not running."
fi

# ---- App container status ----
if [ "${DOCKER_OK}" = true ]; then
    if docker ps --filter "name=${APP_CONTAINER}" --filter "status=running" --format '{{.Names}}' | grep -qw "${APP_CONTAINER}"; then
        echo "App (${APP_CONTAINER}): running"
    else
        echo "App (${APP_CONTAINER}): STOPPED"
        log_warning "Application container '${APP_CONTAINER}' is stopped."
    fi
fi

# ---- Disk threshold check ----
if [ "${DISK_USAGE}" -gt "${DISK_THRESHOLD}" ]; then
    log_warning "Disk usage is ${DISK_USAGE}%, exceeding threshold of ${DISK_THRESHOLD}%."
fi

echo "============================================"
