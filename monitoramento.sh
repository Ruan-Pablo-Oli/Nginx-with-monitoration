#!/usr/bin/env bash

# monitoramento.sh - Script para monitorar se servidor web nginx está ativo
#
# Autor: Ruan Pablo Furtado Oliveira
#
# -----------------------------------------------------------------------------#
#
# Script feito para monitorar o funcionamento de um servidor web e caso ele esteja fora do ar enviar mensagem via webhook para servidor no discord!
#
# Exemplos:
#
# $ ./monitoramento.sh
#
# Histórico:
#
# 1.0v, Ruan Pablo
# - Criação do script
#
#---------------------------------------------VARIÁVEIS--------------------------------------------


set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENV_FILE="/etc/environment"
LOGFILE="/var/log/monitoramento_logs.txt"

touch "$LOGFILE"
chmod 0640 "$LOGFILE"

exec >>"$LOGFILE" 2>&1

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*"
}

notify_discord() {
  local content="$1"
  curl -sS -H "Content-Type: application/json" \
       -d "$(printf '{"content":"%s"}' "$content")" \
       "$WEBHOOK_URL" >>"$LOGFILE" 2>&1 || true
}


[! -e "$ENV_FILE" ] && log "ERROR. Arquivo $ENV_FILE  não encontrado!" && exit 1
[ ! -r "$ENV_FILE" ] && log "ERROR. Sem permissão de leitura em $ENV_FILE " && exit 1

source "$ENV_FILE"

exec 9>"/var/lock/monitoramento.lock" || exit 1
flock -n 9 || exit 0

# Testa se o site responde com HTTP 200
HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$SITE_URL" || echo "000")

if [[ "$HTTP_CODE" != "200" ]]; then
  msg="O site está fora do ar! Código HTTP: $HTTP_CODE."
  log "$msg"
  notify_discord ":x: $msg"
else
  log "Site $SITE_URL OK (HTTP 200)."
fi
[ ! -e "$ENV_FILE" ] && echo "ERROR." 