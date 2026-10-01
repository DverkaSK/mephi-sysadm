# Сборщик логов

Скрипт читает `/var/log/syslog` (если его нет, то `/var/log/auth.log`), отбирает строки со словами `error` и `fail` и сохраняет отчет в `report.txt`.

Запуск: `./script.sh` или `./script.sh /путь/к/логу`. Путь можно передать и через переменную `LOGFILE`. Если нет прав на чтение лога, запускать через `sudo`.

Состояние на момент сдачи ДЗ1 отмечено тегом `hw1`.

## ДЗ2: контейнер, RAID/LVM, nginx с TLS

Машина: Multipass VM, Ubuntu 22.04, дорожка «База».

| Файл | Что делает |
|---|---|
| `Dockerfile` | образ со скриптом и `python3 -m http.server` на порту 8080 |
| `docker-compose.yml` | сервис `my-app`, лог хоста подключен как `/var/log:ro`, отчеты пишутся на LVM-том `/mnt/logs/reports` |
| `storage/raid_lvm.sh` | RAID 1 (`/dev/md0` -> `/mnt/raid`) и LVM (`vg_data/lv_logs` -> `/mnt/logs`) на loop-устройствах |
| `deploy/nginx/my-app.conf` | редирект 80 -> 443, HTTPS с самоподписанным сертификатом, proxy на 127.0.0.1:8080 |
| `deploy/systemd/my-app.service` | служба для контейнера |
| `deploy/systemd/raid-lab.service` | собирает RAID/LVM при загрузке, до старта docker |
| `bootstrap.sh` | поднимает все с нуля на чистой Ubuntu |

Скрипт в контейнере перезапускается каждые `INTERVAL` секунд (по умолчанию 300), свежий отчет доступен по `/report.txt`.

### Запуск

```bash
git clone https://github.com/DverkaSK/mephi-sysadm.git
cd mephi-sysadm
sudo ./bootstrap.sh
```

Повторный запуск безопасен: существующие диски, массив и том не пересоздаются.

### Проверка

```bash
docker build -t my-script .
docker run --rm -v /var/log:/var/log:ro my-script /usr/local/bin/script.sh
cat /proc/mdstat
sudo lvs && sudo vgs
df -h /mnt/raid /mnt/logs
sudo nginx -t
curl -kI https://<адрес-машины>
systemctl status my-app
sudo journalctl -u my-app -n 20
```

Без `-v /var/log:/var/log:ro` скрипт в контейнере сообщает, что лог не найден: у контейнера нет доступа к файлам хоста.

Расширение тома без размонтирования (бонус):

```bash
sudo lvextend -r -L +100M /dev/vg_data/lv_logs
```
