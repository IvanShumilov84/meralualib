#!/bin/bash

# Скрипт сборки библиотеки MeRaLuaLib
# Копирует исходный код из src/ в build/<version>/ согласно SemVer

set -e

# Читаем версию из файла __version.lua
VERSION_FILE="src/__version.lua"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Ошибка: файл $VERSION_FILE не найден!"
    exit 1
fi

# Извлекаем значения major, minor, patch из файла версии
MAJOR=$(grep -oP 'major\s*=\s*\K\d+' "$VERSION_FILE")
MINOR=$(grep -oP 'minor\s*=\s*\K\d+' "$VERSION_FILE")
PATCH=$(grep -oP 'patch\s*=\s*\K\d+' "$VERSION_FILE")

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
    echo "Ошибка: не удалось прочитать версию из $VERSION_FILE"
    exit 1
fi

# Формируем строку версии в формате vMAJOR_MINOR_PATCH (как в get_version_string)
VERSION_STRING="v${MAJOR}_${MINOR}_${PATCH}"

BUILD_PATH="build/${VERSION_STRING}"

echo "Сборка библиотеки MeRaLuaLib"
echo "Версия: ${VERSION_STRING}"
echo "Целевая папка: ${BUILD_PATH}"

# Создаём директорию сборки
mkdir -p "$BUILD_PATH"

# Копируем всё содержимое src/ в build/<version>/
cp -r src/* "$BUILD_PATH/"

echo ""
echo "Замена путей импорта в файлах..."

# Находим все .lua файлы в директории сборки и заменяем lib_path
# Ищем комментарий с токеном @build_token: LIB_PATH_VERSION
# Удаляем этот комментарий и заменяем следующую строку на путь к текущей версии
find "$BUILD_PATH" -name "*.lua" -type f | while read -r file; do
    # Проверяем наличие токена
    if grep -q "@build_token: LIB_PATH_VERSION" "$file"; then
        # Удаляем строку с комментарием-токеном и заменяем следующую строку
        sed -i '/@build_token: LIB_PATH_VERSION/{N;s/-- @build_token: LIB_PATH_VERSION\nlocal lib_path = "meralualib.src."$/local lib_path = "meralualib.'"${VERSION_STRING}".'"/}' "$file"
        echo "Обновлено: $file"
    fi
done

echo ""
echo "Сборка завершена успешно!"
echo "Библиотека доступна в: ${BUILD_PATH}"
