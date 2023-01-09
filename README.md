# Telegram-бот "Train schedule"
Парсит расписание электричек с tutu с учетом выбранного дня и станций (их список предопределен). Написал его, т.к. лень постоянно лезть на их сайт, там вбивать станции и дату. 

## Скриншот
![Application screenshot](https://github.com/dmentry/train_schedule_bot/blob/master/Screenshot.jpg)

## Требования/Зависимости
* Ruby

* gem "dotenv"

* gem "telegram-bot-ruby"

* gem "mechanize"

## Перед запуском
Клонироваать или скачать репозиторий

```
bundle install
```

Переименовать `.env.example` into `.env`
Создать бота с помощью `@BotFather`, вставить его токен в строку `TELEGRAM_BOT_API_TOKEN` вместо `your_token`

## Запустить
```
main.rb
```

## В планах
1. Небольшие изменения в интерфейсе и логике.
2. Рефакторить код.
