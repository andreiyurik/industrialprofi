# Деплой — порядок действий

Первый деплой по шагам, дальше — одна команда. Стек: один VPS, Kamal 2, Docker,
SQLite на персистентном томе. Всё уже настроено в репозитории
(`config/deploy.yml`, `.kamal/secrets`, production-конфиг) — осталось подставить
свои значения и пройти список сверху вниз.

## 0. Что нужно заранее

- **VPS** — 2 ГБ RAM достаточно (SQLite, один контейнер). Чистый Ubuntu LTS,
  доступ root по SSH-ключу. Docker ставить не надо — Kamal поставит сам.
- **Домен** `industrialprofi.com` — A-запись на IP сервера (и `www`, если нужен).
  Проверка: `dig +short industrialprofi.com` должен вернуть IP.
- **GitHub PAT** (Settings → Developer settings → Tokens classic) с правом
  `write:packages` — для реестра образов ghcr.io.
- **SMTP-провайдер** — почта обязательна: без неё не работают регистрация
  (код на email), сброс пароля и алерты об ошибках. Подойдёт любой
  транзакционный SMTP, работающий с RU-доменами (например, smtp.mail.ru
  для бизнеса / Unisender / Mailopost).

## 1. Секреты

```bash
# SMTP — в шифрованные credentials (понадобится config/master.key):
bin/rails credentials:edit
```

```yaml
# добавить блок:
smtp:
  address: smtp.example.com
  port: 587
  user_name: no-reply@industrialprofi.com
  password: "..."
```

```bash
# Токен реестра — в окружение шелла (НЕ в git):
export KAMAL_REGISTRY_PASSWORD=ghp_...   # положи в ~/.bashrc
```

`config/master.key` не коммитится — храни копию в менеджере паролей.

## 2. Конфиг

В `config/deploy.yml` заменить два TODO: IP сервера (`servers.web`) и
username на ghcr.io. Больше там трогать нечего.

## 3. Первый деплой

```bash
bin/kamal setup        # ставит Docker на сервер, собирает образ, поднимает
                       # kamal-proxy c Let's Encrypt, запускает приложение;
                       # БД создаётся и мигрируется автоматически на старте
```

Создать первого администратора и контент:

```bash
ADMIN_EMAIL=... ADMIN_PASSWORD=... bin/kamal app exec "bin/rails db:seed"
```

## 4. Smoke-тест (не пропускать)

1. `https://industrialprofi.com/up` → 200, замок в браузере валидный.
2. Зарегистрироваться с настоящей почтой — код должен прийти (это проверяет SMTP).
3. Войти админом → `/admin` открывается.
4. Отметить любой урок пройденным, создать запись в дневнике с фото.
5. Проверить алерты: `bin/kamal console` → `Rails.error.report(RuntimeError.new("deploy smoke test"), handled: false)` — письмо должно прийти администратору.

## 5. Сразу после первого деплоя

- **Бэкапы — обязательно, до того как появятся живые пользователи.**
  Данные лежат на хосте в docker-томе
  `/var/lib/docker/volumes/industrialprofi_storage/_data` (SQLite-базы + фото).
  Минимум — ежедневный cron на сервере (`apt install sqlite3 rclone`):
  ```bash
  # .backup консистентен даже под нагрузкой (онлайн backup API SQLite)
  sqlite3 /var/lib/docker/volumes/industrialprofi_storage/_data/production.sqlite3 \
    ".backup /root/backups/production-$(date +%F).sqlite3"
  rclone sync /root/backups remote:industrialprofi-backups          # БД
  # фото Active Storage лежат в том же томе (hashed-подпапки) — синхронизируем
  # всё, кроме самих sqlite-файлов (их бэкапит .backup выше):
  rclone sync --exclude "*.sqlite3*" \
    /var/lib/docker/volumes/industrialprofi_storage/_data remote:industrialprofi-files
  ```
  Правильнее — Litestream (потоковая репликация SQLite в S3) как Kamal
  accessory; настроить при первой же свободной сессии. Бэкап без проверки
  восстановления не считается бэкапом — раз в квартал разворачивай дамп локально.
- **Внешний uptime-мониторинг:** UptimeRobot (бесплатный) на
  `https://industrialprofi.com/up`, алерт на почту/Telegram. Внутренний
  мониторинг ошибок уже встроен (`lib/error_subscriber.rb` шлёт письма админам).
- Записать в continuity-документ: доступы к VPS, домену, реестру, SMTP,
  master.key — чтобы проект мог пережить «автобусный фактор».

## Рутина

```bash
bin/kamal deploy       # каждый следующий деплой (зелёный CI — обязателен до)
bin/kamal logs         # хвост логов
bin/kamal console      # rails console на проде
bin/kamal rollback     # откат на предыдущий образ, если деплой плохой
```

Правило из VISION: ship weekly — деплой не событие, а рутина.
