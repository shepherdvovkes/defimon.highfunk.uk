FROM node:18-alpine

WORKDIR /app

# Копируем package.json
COPY package.json ./

# Настраиваем публичный реестр и ставим только prod-зависимости без lockfile
RUN npm config set registry https://registry.npmjs.org/ \
 && npm cache clean --force \
 && npm install --omit=dev --no-audit --no-fund

# Копируем исходный код
COPY . .

# Создаем пользователя для безопасности
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Меняем владельца файлов
RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE 8080

# Проверка здоровья
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node health-checks.js

CMD ["npm", "start"]
