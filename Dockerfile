FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /var/www
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh
ENV INTERVAL=300 PYTHONUNBUFFERED=1
EXPOSE 8080
STOPSIGNAL SIGINT
CMD ["/bin/bash", "-c", "while true; do /usr/local/bin/script.sh; sleep \"$INTERVAL\"; done & exec python3 -m http.server 8080"]
