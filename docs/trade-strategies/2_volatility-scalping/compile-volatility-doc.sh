#!/bin/bash

# Скрипт для компиляции документа стратегии скалпинга на волатильности
# Требует установленный pdflatex

echo "🔧 Компиляция документа стратегии скалпинга на волатильности..."

# Проверка наличия pdflatex
if ! command -v pdflatex &> /dev/null; then
    echo "❌ Ошибка: pdflatex не найден. Установите TeX Live или MiKTeX."
    echo ""
    echo "Для macOS:"
    echo "  brew install --cask mactex"
    echo ""
    echo "Для Ubuntu/Debian:"
    echo "  sudo apt-get install texlive-full"
    echo ""
    exit 1
fi

# Компиляция LaTeX документа
echo "📝 Компиляция LaTeX..."
pdflatex -interaction=nonstopmode volatility-scalping-documentation.tex

# Повторная компиляция для корректного отображения ссылок
echo "🔄 Повторная компиляция для ссылок..."
pdflatex -interaction=nonstopmode volatility-scalping-documentation.tex

# Проверка результата
if [ -f "volatility-scalping-documentation.pdf" ]; then
    echo "✅ Документ успешно скомпилирован!"
    echo "📄 Файл: volatility-scalping-documentation.pdf"
    
    # Размер файла
    file_size=$(du -h volatility-scalping-documentation.pdf | cut -f1)
    echo "📊 Размер: $file_size"
    
    # Количество страниц
    page_count=$(pdfinfo volatility-scalping-documentation.pdf 2>/dev/null | grep "Pages:" | awk '{print $2}')
    if [ ! -z "$page_count" ]; then
        echo "📖 Страниц: $page_count"
    fi
else
    echo "❌ Ошибка компиляции. Проверьте логи выше."
    exit 1
fi

# Очистка временных файлов
echo "🧹 Очистка временных файлов..."
rm -f *.aux *.log *.out *.toc *.fls *.fdb_latexmk *.synctex.gz

echo "🎉 Готово! Документ volatility-scalping-documentation.pdf создан."
