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
: "${KEEP_TEST_DB:=0}"

case "${1:-}" in
    -h|--help) echo "Uso: restore_test.sh [arquivo.sql.gz]"; exit 0 ;;
esac

for cmd in mysql gzip sed; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERRO: comando '$cmd' nao encontrado." >&2; exit 2; }
done

say()  { printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2"; }
fail() { say ERROR "$1"; exit 1; }

if [[ -n "${1:-}" ]]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${DB_NAME}_*.sql.gz" 2>/dev/null \
                   | sort | tail -n 1)"
fi
[[ -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]] || { echo "ERRO: nenhum backup encontrado em $BACKUP_DIR." >&2; exit 2; }

CNF_FILE="$(mktemp)"
TEST_DB="restore_test_$(date '+%Y%m%d%H%M%S')_$$"
DB_CREATED=false

cleanup() {
    local rc=$?
    if $DB_CREATED && [[ "$KEEP_TEST_DB" != "1" && "$TEST_DB" == restore_test_* ]]; then
        mysql --defaults-extra-file="$CNF_FILE" -e "DROP DATABASE IF EXISTS \`$TEST_DB\`" \
            >/dev/null 2>&1 && say INFO "Banco temporario '$TEST_DB' removido." \
            || say WARN "Nao foi possivel remover '$TEST_DB'. Remova manualmente."
    elif $DB_CREATED; then
        say WARN "Banco temporario mantido: $TEST_DB"
    fi
    rm -f "$CNF_FILE"
    exit $rc
}
trap cleanup EXIT
trap 'say ERROR "Teste de restore falhou (linha $LINENO)."' ERR

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

mysql_cli() { mysql --defaults-extra-file="$CNF_FILE" --default-character-set=utf8mb4 "$@"; }
scalar()    { mysql_cli -N -B -e "$1" | tr -d '\r'; }

say INFO "Arquivo testado: $BACKUP_FILE"

gzip -t "$BACKUP_FILE" || fail "Arquivo gzip corrompido."
say INFO "gzip integro."

if gzip -dc "$BACKUP_FILE" | grep -qiE '^(CREATE DATABASE|USE `)'; then
    fail "O dump contem CREATE DATABASE/USE e poderia sobrescrever o banco real. Gere-o sem --databases."
fi

mysql_cli -e "CREATE DATABASE \`$TEST_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
DB_CREATED=true
say INFO "Banco temporario criado: $TEST_DB"

START_TS=$(date +%s)
gzip -dc "$BACKUP_FILE" \
    | LC_ALL=C sed -E 's/DEFINER[[:space:]]*=[[:space:]]*`[^`]*`@`[^`]*`//g' \
    | mysql_cli "$TEST_DB" \
    || fail "Erro durante a restauracao do dump."
say INFO "Dump restaurado sem erros em $(( $(date +%s) - START_TS ))s."

Q="table_schema = '$TEST_DB'"
N_TABLES=$(scalar "SELECT COUNT(*) FROM information_schema.tables WHERE $Q AND table_type='BASE TABLE'")
N_VIEWS=$(scalar  "SELECT COUNT(*) FROM information_schema.views  WHERE $Q")
N_ROUTINES=$(scalar "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$TEST_DB'")
N_TRIGGERS=$(scalar "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='$TEST_DB'")
say INFO "Objetos restaurados: $N_TABLES tabelas, $N_VIEWS views, $N_ROUTINES rotinas, $N_TRIGGERS triggers."

[[ "$N_TABLES" -gt 0 ]] || fail "Nenhuma tabela foi restaurada."

TOTAL_ROWS=0
while IFS= read -r tbl; do
    rows=$(scalar "SELECT COUNT(*) FROM \`$TEST_DB\`.\`$tbl\`") || fail "Tabela ilegivel: $tbl"
    TOTAL_ROWS=$((TOTAL_ROWS + rows))
    say INFO "  tabela $tbl: $rows linha(s)"
done < <(scalar "SELECT table_name FROM information_schema.tables WHERE $Q AND table_type='BASE TABLE' ORDER BY table_name")

while IFS= read -r vw; do
    mysql_cli -e "SELECT 1 FROM \`$TEST_DB\`.\`$vw\` LIMIT 1" >/dev/null \
        || fail "View invalida apos o restore: $vw"
done < <(scalar "SELECT table_name FROM information_schema.views WHERE $Q ORDER BY table_name")

if SRC_TABLES=$(mysql_cli -N -B -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME' AND table_type='BASE TABLE'" 2>/dev/null | tr -d '\r'); then
    if [[ "$SRC_TABLES" != "$N_TABLES" ]]; then
        say WARN "Origem '$DB_NAME' tem $SRC_TABLES tabelas e o restore tem $N_TABLES (estrutura mudou depois do backup?)."
    else
        say INFO "Numero de tabelas confere com a origem '$DB_NAME' ($SRC_TABLES)."
    fi
fi

say INFO "RESTORE TEST: OK ($N_TABLES tabelas, $TOTAL_ROWS linhas) - $(basename "$BACKUP_FILE")"
