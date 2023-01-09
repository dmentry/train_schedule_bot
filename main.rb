require 'dotenv/load'
require 'telegram/bot'
require 'mechanize'
require_relative 'lib/parsing'

URL = 'https://www.tutu.ru/prigorod/'
STATIONS = ['Железнодорожная', 'Ольгино', 'Нижегородская', 'Серп и Молот', 'Москва Курская']
arr1, arr2 = STATIONS.each_slice((STATIONS.size / 2.0).round).to_a

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

from = ''
to = ''
check_date = ''
out = []
quantity_of_packs = 1
schedule_pack_index = 0

parsing = Parsing.new(url: URL)

Telegram::Bot::Client.run(tg_bot_token) do |bot|
  start_bot_time = Time.now.to_i

  bot.listen do |message|
    next if start_bot_time - message.date > 650

    if message.text == '/start'
      out = []
      from = ''
      to = ''
      quantity_of_packs = 1
      schedule_pack_index = 0

      bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}!")
      question = 'Выберите, когда ехать:'
      answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup
        .new(keyboard: [['Сегодня', 'Завтра']], one_time_keyboard: true, resize_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)


    elsif message.text == '/stop'
      out = []
      from = ''
      to = ''
      quantity_of_packs = 1
      schedule_pack_index = 0

      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!", reply_markup: kb)

    elsif STATIONS.include?(message.text)
      if from.empty?
        from = message.text
      else
        to = message.text
      end

      if to.empty?
        question = 'Выберите станцию прибытия из списка:'
        answers =
          Telegram::Bot::Types::ReplyKeyboardMarkup
          .new(keyboard: [arr1, arr2], one_time_keyboard: true, resize_keyboard: true)
        bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
      end

      if !from.empty? && !to.empty?
        out = parsing.schedule(from: from, to: to, check_date: check_date)

        quantity_of_packs = out.size - 1

        out[schedule_pack_index].each do |schedule_line|
          bot.api.send_message(chat_id: message.chat.id, text: schedule_line)

          if schedule_line == "Электричек на указанную дату нет."
            kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!", reply_markup: kb)
            out = []
            from = ''
            to = ''
            quantity_of_packs = 1
            schedule_pack_index = 0            
          end
        end

        schedule_pack_index += 1

        if schedule_pack_index <= quantity_of_packs 
          question = 'Еще?'
          answers =
            Telegram::Bot::Types::ReplyKeyboardMarkup
            .new(keyboard: [['Да', 'Нет']], one_time_keyboard: true, resize_keyboard: true)
          bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        end
      end
    elsif message.text == 'Сегодня'
      check_date = Date.today.to_s


        question = 'Выберите станцию отправления из списка:'
        answers =
          Telegram::Bot::Types::ReplyKeyboardMarkup
          .new(keyboard: [arr1, arr2], one_time_keyboard: true, resize_keyboard: true)
        bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
    elsif message.text == 'Завтра'
      check_date = (Date.today + 1).to_s

        question = 'Выберите станцию отправления из списка:'
        answers =
          Telegram::Bot::Types::ReplyKeyboardMarkup
          .new(keyboard: [arr1, arr2], one_time_keyboard: true, resize_keyboard: true)
        bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
    elsif message.text == 'Да'
      if !out.empty?
        out[schedule_pack_index].each do |schedule_line|
          bot.api.send_message(chat_id: message.chat.id, text: schedule_line)
        end
        schedule_pack_index += 1

        if schedule_pack_index <= quantity_of_packs 
            question = 'Еще?'
            answers =
              Telegram::Bot::Types::ReplyKeyboardMarkup
              .new(keyboard: [['Да', 'Нет']], one_time_keyboard: true, resize_keyboard: true)
            bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
        else
          kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
          bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!", reply_markup: kb)
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Сначала начните диалог, нажав на '/start'")
      end
    elsif message.text == 'Нет'
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!", reply_markup: kb)
      out = []
      from = ''
      to = ''
      quantity_of_packs = 1
      schedule_pack_index = 0
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Извините, такой команды нет.")
      out = []
      from = ''
      to = ''
      quantity_of_packs = 1
      schedule_pack_index = 0
    end
  end
end
