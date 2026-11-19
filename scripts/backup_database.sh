#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="${BACKUP_ENV_FILE:-$SCRIPT_DIR/backup.env}"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

: "${DB_HOST:=127.0.0.1}"
: "${DB_PORT:=3306}"
: "${DB_NAME:=confeccoes}"
: "${DB_USER:=root}"
: "${DB_PASS:=}"
: "${BACKUP_DIR:=$SCRIPT_DIR/../backups}"
: "${RETENTION_DAYS:=7}"
: "${DUMP_OPTS:=--single-transaction --quick --routines --triggers --events --hex-blob --default-character-set=utf8mb4 --no-tablespaces --set-gtid-purged=OFF}"

RUN_VERIFY=false
for arg in "$@"; do
    case "$arg" in
        --verify) RUN_VERIFY=true ;;
        -h|--help) echo "Uso: backup_database.sh [--verify]"; exit 0 ;;
        *) echo "Argumento desconhecido: $arg (use --help)" >&2; exit 2 ;;
    esac
done

for cmd in mysqldump gzip find; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERRO: comando '$cmd' nao encontrado." >&2; exit 2; }
done
[[ "$RETENTION_DAYS" =~ ^[0-9]+$ && "$RETENTION_DAYS" -ge 1 ]] || {
    echo "ERRO: RETENTION_DAYS deve ser um inteiro >= 1." >&2; exit 2; }

mkdir -p "$BACKUP_DIR"
BACKUP_DIR="$(cd "$BACKUP_DIR" && pwd)"
LOG_FILE="$BACKUP_DIR/backup.log"

log() { printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" | tee -a "$LOG_FILE" >&2; }

CNF_FILE="$(mktemp)"
TMP_DUMP=""
ERR_FILE="$(mktemp)"
LOCK_DIR=""
cleanup() { rm -f "$CNF_FILE" "$ERR_FILE" ${TMP_DUMP:+"$TMP_DUMP"}; [[ -n "$LOCK_DIR" ]] && rmdir "$LOCK_DIR" 2>/dev/null || true; }
trap cleanup EXIT
trap 'log ERROR "Backup falhou (linha $LINENO). Veja o log: $LOG_FILE"; exit 1' ERR

if command -v flock >/dev/null 2>&1; then
    exec 9>"$BACKUP_DIR/.backup.lock"
    flock -n 9 || { log WARN "Outro backup ja esta em execucao. Abortando."; exit 1; }
else
    if mkdir "$BACKUP_DIR/.backup.lock.d" 2>/dev/null; then
        LOCK_DIR="$BACKUP_DIR/.backup.lock.d"
    else
        log WARN "Outro backup ja esta em execucao (ou sobrou $BACKUP_DIR/.backup.lock.d). Abortando."
        exit 1
    fi
fi

{
    echo "[client]"
    echo "host=$DB_HOST"
    echo "port=$DB_PORT"
    echo "user=$DB_USER"
    if [[ -n "$DB_PASS" ]]; then
        pass_escaped="${DB_PASS//\\/\\\\}"
        pass_escaped="${pass_escaped//\"/\\\"}"
        echo "password=\"$pass_escaped\""
    fi
} > "$CNF_FILE"
chmod 600 "$CNF_FILE"

TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
FINAL_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"
TMP_DUMP="$FINAL_FILE.partial"

log INFO "Iniciando backup de '$DB_NAME' em $DB_HOST:$DB_PORT"

read -r -a DUMP_OPTS_ARR <<< "$DUMP_OPTS"
if ! mysqldump --defaults-extra-file="$CNF_FILE" "${DUMP_OPTS_ARR[@]}" "$DB_NAME" \
        2> "$ERR_FILE" | gzip -9 > "$TMP_DUMP"; then
    log ERROR "mysqldump falhou: $(tr '\n' ' ' < "$ERR_FILE")"
    exit 1
fi

gzip -t "$TMP_DUMP" || { log ERROR "Arquivo gzip corrompido."; exit 1; }

if ! gzip -dc "$TMP_DUMP" | tail -n 5 | grep -q -- '-- Dump completed'; then
    log ERROR "Dump incompleto (marcador final '-- Dump completed' ausente)."
    exit 1
fi
if ! gzip -dc "$TMP_DUMP" | grep -q -m1 '^CREATE TABLE'; then
    log ERROR "Dump nao contem nenhuma tabela."
    exit 1
fi

mv "$TMP_DUMP" "$FINAL_FILE"
TMP_DUMP=""
SIZE="$(du -h "$FINAL_FILE" | cut -f1)"
log INFO "Backup OK: $FINAL_FILE ($SIZE)"

PURGED=0
while IFS= read -r -d '' old_file; do
    rm -f -- "$old_file"
    log INFO "Expurgado (> ${RETENTION_DAYS} dias): $(basename "$old_file")"
    PURGED=$((PURGED + 1))
done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.sql.gz" \
              -mmin +$((RETENTION_DAYS * 1440)) -print0)
REMAINING="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.sql.gz" | wc -l)"
log INFO "Expurgo concluido: $PURGED removido(s), $REMAINING backup(s) mantido(s)."

if $RUN_VERIFY; then
    log INFO "Executando teste de restore..."
    BACKUP_ENV_FILE="$CONFIG_FILE" bash "$SCRIPT_DIR/restore_test.sh" "$FINAL_FILE" \
        || { log ERROR "Teste de restore FALHOU para $FINAL_FILE"; exit 1; }
fi

log INFO "Processo finalizado com sucesso."
