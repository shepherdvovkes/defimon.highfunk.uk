# Используем multi-stage build для оптимизации
FROM rust:1.75-slim-bullseye as builder

# Аргументы сборки
ARG RUST_TARGET=x86_64-unknown-linux-gnu

# Установка системных зависимостей для сборки
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Установка target для указанной архитектуры
RUN rustup target add $RUST_TARGET

# Создание рабочей директории
WORKDIR /app

# Копирование Rust зависимостей
COPY Cargo.toml Cargo.lock ./

# Создание dummy main.rs для кэширования зависимостей
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --target $RUST_TARGET --release

# Копирование исходного кода
COPY src ./src

# Сборка для указанной архитектуры
RUN cargo build --target $RUST_TARGET --release

# Финальный образ
FROM ubuntu:22.04

# Установка runtime зависимостей
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя для безопасности
RUN useradd -m -u 1000 appuser

# Создание рабочей директории
WORKDIR /app

# Копирование скомпилированного бинарного файла
COPY --from=builder /app/target/$RUST_TARGET/release/blockchain-node /app/blockchain-node

# Копирование скриптов
COPY scripts ./scripts
RUN chmod +x scripts/*.sh

# Создание директории для данных
RUN mkdir -p /data/ethereum && chown -R appuser:appuser /data

# Переключение на пользователя
USER appuser

# Экспорт портов
EXPOSE 8545 8546 30303 30303/udp

# Запуск ноды
CMD ["./blockchain-node"]
