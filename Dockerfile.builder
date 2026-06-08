FROM alpine:latest

# Установка необходимых пакетов
RUN apk add --no-cache \
    git \
    docker-cli \
    bash

# Копируем скрипт
COPY builder.sh /builder.sh

# Делаем скрипт исполняемым
RUN chmod +x /builder.sh

# Точка входа — наш скрипт
ENTRYPOINT ["/builder.sh"]

