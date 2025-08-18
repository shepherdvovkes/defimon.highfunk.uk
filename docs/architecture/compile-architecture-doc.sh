#!/bin/bash

# Скрипт для компиляции архитектурной документации

echo "Компиляция архитектурной документации DEFIMON..."

# Проверка наличия pdflatex
if ! command -v pdflatex &> /dev/null; then
    echo "Ошибка: pdflatex не найден. Установите TeX Live или MiKTeX."
    echo "Для macOS: brew install --cask mactex"
    echo "Для Ubuntu/Debian: sudo apt-get install texlive-full"
    exit 1
fi

# Компиляция документа (два прохода для правильной нумерации)
pdflatex -interaction=nonstopmode architecture-documentation.tex
pdflatex -interaction=nonstopmode architecture-documentation.tex

# Очистка временных файлов
rm -f *.aux *.log *.toc *.out

if [ -f architecture-documentation.pdf ]; then
    echo "✅ Документ успешно скомпилирован: architecture-documentation.pdf"
    
    # Открыть PDF если на macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open architecture-documentation.pdf
    fi
else
    echo "❌ Ошибка при компиляции документа"
    exit 1
fi
