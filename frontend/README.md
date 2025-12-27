# Frontend - Інструкції з запуску

Цей проект містить Next.js додаток та статичні HTML сторінки.

## Вимоги

- **Node.js** версії 18 або вище
- **Python 3** (для запуску статичних файлів через HTTP сервер)
- **npm** або **yarn**

## Встановлення залежностей

```bash
cd frontend
npm install
```

## Способи запуску

### 1. Запуск статичних HTML файлів через Python HTTP сервер

Цей спосіб підходить для швидкого перегляду статичних сторінок (наприклад, `/public/courtapp/index.html`).

```bash
cd frontend/public
python3 -m http.server 8010 --bind 127.0.0.1
```

Після запуску сайт буде доступний за адресою:
- **Локально**: http://127.0.0.1:8010
- **Головна сторінка**: http://127.0.0.1:8010/index.html
- **CourtApp**: http://127.0.0.1:8010/courtapp/index.html

**Для доступу з інших машин в мережі:**
```bash
python3 -m http.server 8010 --bind 0.0.0.0
```

### 2. Запуск через Next.js Development Server

Цей спосіб підходить для розробки з підтримкою React компонентів та Tailwind CSS.

```bash
cd frontend
npm run dev
```

Після запуску сайт буде доступний за адресою:
- **Локально**: http://localhost:3000
- **З інших машин**: http://<IP_адреса_сервера>:3000

**Для доступу з інших машин в мережі:**
```bash
npm run dev -- -H 0.0.0.0
```

### 3. Production Build

Для production збірки:

```bash
cd frontend
npm run build
npm start
```

## Структура проекту

```
frontend/
├── app/                    # Next.js App Router компоненти
│   ├── globals.css        # Глобальні стилі з Tailwind
│   ├── layout.tsx         # Кореневий layout
│   └── page.tsx           # Головна сторінка
├── public/                 # Статичні файли
│   ├── index.html         # Статична головна сторінка
│   ├── courtapp/          # CourtApp статичні сторінки
│   │   ├── index.html
│   │   └── styles.css
│   └── images/            # Зображення
├── package.json
├── next.config.js         # Конфігурація Next.js
└── tailwind.config.js     # Конфігурація Tailwind CSS
```

## Порти

- **8010** - Python HTTP сервер (статичні файли)
- **3000** - Next.js Development Server (за замовчуванням)

## Примітки

- Статичні HTML файли в `/public` доступні через обидва способи запуску
- Next.js автоматично обслуговує файли з `/public` за шляхом `/`
- Для production використовуйте `npm run build` та `npm start`

## Troubleshooting

### Порт зайнятий

Якщо порт зайнятий, використовуйте інший:

```bash
# Python HTTP сервер на іншому порті
python3 -m http.server 8080 --bind 127.0.0.1

# Next.js на іншому порті
PORT=3001 npm run dev
```

### Стилі не завантажуються

Переконайтеся, що:
1. Шляхи до CSS файлів правильні в HTML
2. Сервер запущено з правильної директорії
3. Для Next.js - перевірте `tailwind.config.js` та `globals.css`

