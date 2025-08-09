#!/bin/bash

# Скрипт для запуска API сервера для Admin Monitor App

echo "Starting Admin Monitor API Server..."

# Проверяем, установлен ли Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 is not installed"
    exit 1
fi

# Проверяем, установлены ли зависимости
if [ ! -f "requirements.txt" ]; then
    echo "Error: requirements.txt not found"
    exit 1
fi

# Устанавливаем зависимости
echo "Installing dependencies..."
pip3 install -r requirements.txt

# Проверяем, что API сервер существует
if [ ! -f "api_server.py" ]; then
    echo "Error: api_server.py not found"
    exit 1
fi

# Запускаем API сервер
echo "Starting API server on http://0.0.0.0:3000"
echo "Press Ctrl+C to stop"
python3 api_server.py
