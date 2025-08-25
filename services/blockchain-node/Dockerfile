FROM ubuntu:22.04

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Установка Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Установка Go для Geth
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz && \
    rm go1.21.0.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Клонирование и сборка Geth
RUN git clone https://github.com/ethereum/go-ethereum.git && \
    cd go-ethereum && \
    make geth && \
    cp build/bin/geth /usr/local/bin/ && \
    cd .. && \
    rm -rf go-ethereum

# Создание рабочей директории
WORKDIR /app

# Копирование Rust зависимостей
COPY Cargo.toml Cargo.lock ./
COPY src ./src

# Сборка Rust приложения
RUN cargo build --release

# Копирование скриптов
COPY scripts ./scripts
RUN chmod +x scripts/*.sh

# Создание директории для данных
RUN mkdir -p /data/ethereum

# Экспорт портов
EXPOSE 8545 8546 30303 30303/udp

# Запуск ноды
CMD ["./scripts/start-node.sh"]
