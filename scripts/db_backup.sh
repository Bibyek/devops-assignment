#!/usr/bin/env bash
#
# db_backup.sh
# Dumps the PostgreSQL database from the running container,
# compresses it with gzip, and stores it in /var/backups/db/
# with a timestamped filename.
#
set -euo pipefail

# ---- Config ----
DB_CONTAINER="postgres_db"
BACKUP_DIR="/var/backups/db"
TIMESTAMP="$(date '+%Y%m%d')"
BACKUP_FILE="${BACKUP_DIR}/db_backup_${TIMESTAMP}.sql.gz"

# Load DB credentials from the project .env
ENV_FILE="/home/trainee/devops-assignment/.env"
if [ ! -f "${ENV_FILE}" ]; then
    echo "[ERROR] Env file not found at ${ENV_FILE}" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "${ENV_FILE}"

# ---- Ensure backup directory exists ----
mkdir -p "${BACKUP_DIR}"

# ---- Perform the dump ----
echo "Starting backup of database '${POSTGRES_DB}' from container '${DB_CONTAINER}'..."

if docker exec "${DB_CONTAINER}" pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" | gzip > "${BACKUP_FILE}"; then
    echo "[SUCCESS] Backup created: ${BACKUP_FILE}"
    echo "Size: $(du -h "${BACKUP_FILE}" | cut -f1)"
else
    echo "[ERROR] Backup failed." >&2
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# ---- Optional retention: keep last 7 daily backups ----
find "${BACKUP_DIR}" -name "db_backup_*.sql.gz" -type f -mtime +7 -delete
echo "Old backups (>7 days) pruned. Retention: 7 daily backups."
