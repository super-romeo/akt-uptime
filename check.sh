#!/usr/bin/env bash
# Проверка akt.veridok.ru и сигнал в Healthchecks. HC_PING_URL — секрет репозитория.
set -u
base=${BASE:-https://akt.veridok.ru}
fail=""

check() { # путь, строка, которая должна быть в ответе
  local out code
  out=$(curl -sS -L --max-time 20 -w $'\n%{http_code}' "$base$1") || { fail="$fail $1:сеть"; return; }
  code=${out##*$'\n'}
  [ "$code" = 200 ] || { fail="$fail $1:$code"; return; }
  printf '%s' "$out" | grep -qF -- "$2" || fail="$fail $1:нет_строки"
}

check / "ВозражениеАкт"
check /form/ekspress "webform-submission-ekspress-form"
check /vozrazhenie/tariffs '"currency":"RUB"'

if [ -z "$fail" ]; then echo "OK"; else echo "сбой:$fail"; fi

if [ -z "${HC_PING_URL:-}" ]; then
  echo "::warning::секрета HC_PING_URL нет — сигнал не отправлен"
elif [ -z "$fail" ]; then
  curl -fsS -m 10 --retry 3 -o /dev/null "$HC_PING_URL"
else
  curl -fsS -m 10 --retry 3 -o /dev/null --data-raw "сбой:$fail" "$HC_PING_URL/fail"
fi

[ -z "$fail" ]
