class Bot
  def initialize(max_lines:, bot_token:, url:)
    @max_lines    = max_lines
    @bot_token    = bot_token
    @url          = url
    @out  = []

    clear_values
  end

  def main_method
    parsing = Parsing.new(url: @url)

    loop do
      begin
        Telegram::Bot::Client.run(@bot_token) do |bot|
          start_bot_time = Time.now.to_i

          bot.listen do |message|
            next if start_bot_time - message.date > 650

            # if !message&.text.nil?
            if message.respond_to?(:text)
              File.open('users_id.txt', "a:UTF-8") do |file| 
                file.puts("#{ Time.now.strftime("%d.%m.%Y %T") }, id: #{ message.chat.id }, username: #{ message.chat.username }.")
              end

              if message.text == '/start'
                clear_values

                bot.api.send_Message(chat_id: message.chat.id, text: 'Привет!')

                send_msg_with_keabord(bot: bot, message: message, question: 'Выберите, когда ехать:', keyboard_values: [[text: 'Сегодня'], [text: 'Завтра']])
              elsif message.text == '/stop'
                bye_message(bot: bot, message: message)

                clear_values
              elsif STATIONS_LIST1.include?(message.text.strip.downcase) || STATIONS_LIST2.include?(message.text.strip.downcase)
                station_name = if STATIONS_LIST2.include?(message.text.strip.downcase)
                                 'Москва Курская'
                               else
                                 message.text.strip
                               end
                if @from.empty?
                  @from = station_name
                else
                  @to = station_name
                end

                if @to.empty?
                  send_msg_with_keabord(bot: bot, message: message, question: 'Выберите станцию прибытия из списка:', keyboard_values: [BUTTONS_ARR1, BUTTONS_ARR2])
                end

                if !@from.empty? && !@to.empty?
                  @out = parsing.schedule(from: @from, to: @to, check_date: @check_date, max_lines: MAX_LINES)

                  @quantity_of_schedule_packs = @out.size - 1

                  @out[@schedule_pack_index].each do |schedule_line|
                    bot.api.send_message(chat_id: message.chat.id, text: schedule_line, parse_mode: 'HTML')

                    if schedule_line == "Электричек на указанную дату нет."
                      clear_values
                      # Если не приравнять к нулю, то дальше из-за условия выскочит вопрос 'Еще?'
                      @quantity_of_schedule_packs = 0
                    end
                  end

                  @schedule_pack_index += 1

                  if @schedule_pack_index <= @quantity_of_schedule_packs 
                    send_msg_with_keabord(bot: bot, message: message, question: 'Еще?', keyboard_values: [[text: '✔️ Да'], [text: '❌ Нет']])
                  else
                    bye_message(bot: bot, message: message)
                  end
                end
              elsif message.text == 'Сегодня'
                @check_date = Date.today

                send_msg_with_keabord(bot: bot, message: message, question: 'Выберите станцию отправления из списка:', keyboard_values: [BUTTONS_ARR1, BUTTONS_ARR2])
              elsif message.text == 'Завтра'
                @check_date = (Date.today + 1)

                send_msg_with_keabord(bot: bot, message: message, question: 'Выберите станцию отправления из списка:', keyboard_values: [BUTTONS_ARR1, BUTTONS_ARR2])
              elsif message.text.match?(/\sДа\z/)
                if !@out.empty?
                  @out[@schedule_pack_index].each do |schedule_line|
                    bot.api.send_message(chat_id: message.chat.id, text: schedule_line, parse_mode: 'HTML')
                  end

                  @schedule_pack_index += 1

                  if @schedule_pack_index <= @quantity_of_schedule_packs 
                    send_msg_with_keabord(bot: bot, message: message, question: 'Еще?', keyboard_values: [[text: '✔️ Да'], [text: '❌ Нет']])
                  else
                    bye_message(bot: bot, message: message)
                  end
                else
                  bot.api.send_message(chat_id: message.chat.id, text: "Сначала начните диалог, нажав на '/start'")
                end
              elsif message.text.match?(/\sНет\z/)
                bye_message(bot: bot, message: message)

                clear_values
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Неизвестная команда.")
                bye_message(bot: bot, message: message, additional_text: "Попробуйте начать заново, нажав /start.\n")

                clear_values
              end
            else
              clear_values

              bye_message(bot: bot, message: message, additional_text: "Попробуйте начать заново, нажав /start.\n")
            end
          end
        end
      rescue => e
        File.open('tg_bot_log.txt', "a:UTF-8") do |file| 
          file.puts("#{ Time.now }:")
          file.puts('Ошибка в главном цикле:')
          file.puts("Класс ошибки: #{ e.class }")
          file.puts("Сообщение ошибки: #{ e.message }")
        end
      end
    end  
  end

  private

  def send_msg_with_keabord(bot:, message:, question:, keyboard_values:)
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard_values, one_time_keyboard: true, resize_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
  end

  def bye_message(bot:, message:, additional_text: '')
    bye_text = additional_text + 'Пока!'
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    begin
      bot.api.send_message(chat_id: message.chat.id, text: bye_text, reply_markup: kb, parse_mode: 'HTML')
    rescue => e
      File.open('tg_bot_log.txt', "a:UTF-8") do |file| 
        file.puts("#{ Time.now }:")
        file.puts('Ошибка в send_message:')
        file.puts("Класс ошибки: #{ e.class }")
        file.puts("Сообщение ошибки: #{ e.message }")
      end
    end
  end

  def clear_values
    @out  = []
    @from = ''
    @to   = ''
    @quantity_of_schedule_packs = 1
    @schedule_pack_index        = 0
  end
end
