#!/bin/bash

# Скрипт для компиляции документации по арбитражной стратегии

echo "Компиляция документации по арбитражной стратегии DEFIMON..."

# Проверка наличия pdflatex
if ! command -v pdflatex &> /dev/null; then
    echo "Ошибка: pdflatex не найден. Установите TeX Live или MiKTeX."
    echo "Для macOS: brew install --cask mactex"
    echo "Для Ubuntu/Debian: sudo apt-get install texlive-full"
    exit 1
fi

# Компиляция документа (два прохода для правильной нумерации)
pdflatex -interaction=nonstopmode arbitrage-strategy-documentation.tex
pdflatex -interaction=nonstopmode arbitrage-strategy-documentation.tex

# Очистка временных файлов
rm -f *.aux *.log *.toc *.out

if [ -f arbitrage-strategy-documentation.pdf ]; then
    echo "✅ Документ успешно скомпилирован: arbitrage-strategy-documentation.pdf"
    
    # Открыть PDF если на macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open arbitrage-strategy-documentation.pdf
    fi
else
    echo "❌ Ошибка при компиляции документа"
    exit 1
fi
