#!/bin/bash
set -eu

cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
    echo "Запустите через sudo" >&2
    exit 1
fi

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io docker-compose-v2 mdadm lvm2 nginx openssl curl

install -m 755 storage/raid_lvm.sh /usr/local/sbin/raid_lvm.sh
cp deploy/systemd/raid-lab.service /etc/systemd/system/raid-lab.service
systemctl daemon-reload
systemctl enable raid-lab
systemctl restart raid-lab

docker compose up -d --build

if [ ! -f /etc/ssl/certs/my-app.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/my-app.key \
        -out /etc/ssl/certs/my-app.crt \
        -subj "/CN=my-app.local"
fi

cp deploy/nginx/my-app.conf /etc/nginx/sites-available/my-app
ln -sf /etc/nginx/sites-available/my-app /etc/nginx/sites-enabled/my-app
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

cp deploy/systemd/my-app.service /etc/systemd/system/my-app.service
systemctl daemon-reload
systemctl enable my-app
systemctl restart my-app
sleep 3

systemctl --no-pager status my-app | head -n 5
curl -skI https://127.0.0.1
