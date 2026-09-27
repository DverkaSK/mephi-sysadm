#!/bin/bash

LOGFILE="${1:-/var/log/syslog}"
REPORT="report.txt"
KEYWORDS="error|fail"

if [ -z "$1" ] && [ ! -f "$LOGFILE" ]; then
    LOGFILE="/var/log/auth.log"
fi

if [ ! -f "$LOGFILE" ]; then
    echo "Ошибка: файл $LOGFILE не найден" >&2
    exit 1
fi

if [ ! -r "$LOGFILE" ]; then
    echo "Ошибка: нет прав на чтение $LOGFILE, запустите через sudo" >&2
    exit 1
fi

if ! touch "$REPORT" 2>/dev/null; then
    echo "Ошибка: нет прав на запись $REPORT в $(pwd)" >&2
    exit 1
fi

TOTAL=$(grep -aicE "$KEYWORDS" "$LOGFILE")

{
    echo "Отчет по файлу: $LOGFILE"
    echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Найдено строк: $TOTAL"
    for word in ${KEYWORDS//|/ }; do
        echo "  $word: $(grep -aic "$word" "$LOGFILE")"
    done
    echo
    if [ "$TOTAL" -eq 0 ]; then
        echo "Совпадений не найдено"
    else
        grep -aiE "$KEYWORDS" "$LOGFILE"
    fi
} > "$REPORT"

echo "Готово: $REPORT, найдено строк: $TOTAL"
