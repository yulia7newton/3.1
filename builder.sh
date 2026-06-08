#!/bin/bash

# Проверка аргументов
if [ $# -ne 2 ]; then
    echo "Ошибка: Нужно указать два аргумента"
    echo "Использование: ./builder.sh <GitHub-репозиторий> <Docker-Hub-репозиторий>"
    echo "Пример: ./builder.sh mluukkai/express_app mluukkai/testing"
    exit 1
fi

GITHUB_REPO=$1
DOCKER_REPO=$2

# Логин в Docker Hub (если переданы переменные окружения)
if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PWD" ]; then
    echo "Логин в Docker Hub как $DOCKER_USER..."
    echo "$DOCKER_PWD" | docker login -u "$DOCKER_USER" --password-stdin
    if [ $? -ne 0 ]; then
        echo "Ошибка: Не удалось войти в Docker Hub"
        exit 1
    fi
    echo "✓ Успешный вход в Docker Hub"
fi

# Извлекаем имя пользователя и репозитория из GitHub URL или "user/repo"
if [[ "$GITHUB_REPO" == *"/"* ]]; then
    # Формат: "user/repo" или "https://github.com/user/repo"
    REPO_NAME=$(basename "$GITHUB_REPO")
    CLONE_URL="https://github.com/${GITHUB_REPO}.git"
else
    echo "Ошибка: Неверный формат GitHub репозитория"
    echo "Используйте формат: username/repo-name"
    exit 1
fi

echo "========================================="
echo "Скрипт сборки и публикации Docker образа"
echo "========================================="
echo "GitHub репозиторий: $GITHUB_REPO"
echo "Docker Hub репозиторий: $DOCKER_REPO"
echo "========================================="

# Временная папка для клонирования
TEMP_DIR="/tmp/builder_$$"

# Шаг 1: Клонирование репозитория
echo ""
echo "[1/4] Клонирование репозитория $CLONE_URL ..."
git clone "$CLONE_URL" "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось клонировать репозиторий"
    exit 1
fi
echo "✓ Репозиторий склонирован в $TEMP_DIR"

# Переход в папку с кодом
cd "$TEMP_DIR"

# Шаг 2: Проверка наличия Dockerfile
echo ""
echo "[2/4] Проверка наличия Dockerfile..."
if [ ! -f "Dockerfile" ]; then
    echo "Ошибка: Dockerfile не найден в корне репозитория"
    exit 1
fi
echo "✓ Dockerfile найден"

# Шаг 3: Сборка Docker образа
echo ""
echo "[3/4] Сборка Docker образа $DOCKER_REPO:latest ..."
docker build -t "$DOCKER_REPO:latest" .

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось собрать Docker образ"
    exit 1
fi
echo "✓ Docker образ собран"

# Шаг 4: Публикация в Docker Hub
echo ""
echo "[4/4] Публикация в Docker Hub..."
docker push "$DOCKER_REPO:latest"

if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось запушить образ в Docker Hub"
    echo "Убедитесь, что вы залогинены: docker login"
    exit 1
fi
echo "✓ Образ запушен в Docker Hub"

# Очистка
echo ""
echo "Очистка временных файлов..."
cd /
rm -rf "$TEMP_DIR"

echo ""
echo "========================================="
echo "ГОТОВО! ✓"
echo "Образ доступен: docker pull $DOCKER_REPO:latest"
echo "========================================="

