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

grep -aiE "$KEYWORDS" "$LOGFILE" > "$REPORT"
echo "Готово: $REPORT, найдено строк: $(wc -l < "$REPORT")"
