#!/bin/bash

# Скрипт для обрезки видео с черными границами
# Использование: ./crop_videos.sh [папка_с_видео] [выходная_папка]

set -e

# Проверяем наличие Python
if ! command -v python3 &> /dev/null; then
    echo "Ошибка: Python3 не установлен"
    exit 1
fi

# Проверяем наличие pip
if ! command -v pip3 &> /dev/null; then
    echo "Ошибка: pip3 не установлен"
    exit 1
fi

# Устанавливаем зависимости
echo "Установка зависимостей..."
pip3 install -r video_crop_requirements.txt

# Делаем скрипт исполняемым
chmod +x video_crop_tool.py

# Проверяем аргументы
if [ $# -eq 0 ]; then
    echo "Использование: $0 [папка_с_видео] [выходная_папка]"
    echo ""
    echo "Примеры:"
    echo "  $0 ./видео                    # Обработать папку 'видео'"
    echo "  $0 ./видео ./обрезанные       # Обработать папку 'видео' и сохранить в 'обрезанные'"
    echo "  $0 video.mp4                  # Обработать один файл"
    echo "  $0 video.mp4 cropped.mp4      # Обработать файл с указанием выходного имени"
    exit 1
fi

INPUT="$1"
OUTPUT="$2"

# Запускаем инструмент
if [ -d "$INPUT" ]; then
    # Обработка папки
    if [ -z "$OUTPUT" ]; then
        OUTPUT="${INPUT}_cropped"
    fi
    echo "Обработка папки: $INPUT -> $OUTPUT"
    python3 video_crop_tool.py "$INPUT" -o "$OUTPUT" -d
else
    # Обработка одного файла
    if [ -z "$OUTPUT" ]; then
        echo "Обработка файла: $INPUT"
        python3 video_crop_tool.py "$INPUT"
    else
        echo "Обработка файла: $INPUT -> $OUTPUT"
        python3 video_crop_tool.py "$INPUT" -o "$OUTPUT"
    fi
fi

echo "Готово!"
