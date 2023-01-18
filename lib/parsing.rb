class Parsing
  def initialize(url:)
    @url ||= url
  end

  def schedule(from:, to:, check_date:, max_lines:)
    # Начинаем считать с 2, т.к. изначально добавляется строка с заголовком
    i = 2

    check_date = check_date.to_s

    mechanize = Mechanize.new
    page = mechanize.get(@url)
    form = page.forms[3]
    form['st1']  = from
    form['st2']  = to
    form['date'] = check_date
    page = form.submit

    schedule_page_link = page.uri.to_s

    html = URI.open(schedule_page_link)
    doc = Nokogiri::HTML(html)

    # Выбираем элементы tr у которых в названии класса нет goneTrain
    parsed_doc = doc.css("tr:not([class*=goneTrain])").map { |x| x.text }
    # Удаляем лишние строки
    parsed_doc = parsed_doc[1..-2]

    out = []
    temp_arr = []
    header = "<b>#{ from }</b> \xE2\x9E\xA1 <b>#{ to }</b> на <b>#{ Date.parse(check_date).strftime("%d.%m.%Y") }</b>:"

    temp_arr << header

    parsed_doc.each do |line|
      # Удаляем лишнюю строку
      next if !line.match?(/(?:[a-zA-Zа-яА-Я])((\d{2}.м)|(\d.м))/){ $1 }

      # Убрать текст в скобках между временем отправления и прибытия
      line=line.gsub("#{line.match(/(?:\A\d{2}:\d{2})([А-ЯЁа-яё().\s\d]+)(?:\d{2}:\d{2})/){$1}}", '') if line.match?(/(?:\A\d{2}:\d{2})([А-ЯЁа-яё().\s\d]+)(?:\d{2}:\d{2})/)

      departure = line.match(/\A\d{2}:\d{2}/).to_s
      arrival = line.match(/(?<!^)(\d{2}:\d{2})/).to_s
      time_to_drive = line.match(/(?:[a-zA-Zа-яА-Я])((\d{2}.м)|(\d.м))/){ $1 }[0..-3]

      from_to = line.match(/(?:м)([А-ЯЁ].+)/){ $1 }
      from_to = from_to.gsub(/(\d+.₽.*)/, '') if from_to.match?(/\d+.₽.*/)

      price = line.match(/(\d+)(?:.₽)/){ $1 } if line.match?(/(\d+)(.₽)/)

      temp_arr << if price
                    "Отпр: <b>#{ departure }</b>. Приб: <b>#{ arrival }</b>. \xF0\x9F\x9A\x82 <b>#{ time_to_drive }мин</b>. Стоимость: <b>#{price}руб</b>.\n#{from_to}"
                  else
                    "Отпр: <b>#{ departure }</b>. Приб: <b>#{ arrival }</b>. \xF0\x9F\x9A\x82 <b>#{ time_to_drive }мин</b>.\nСтоимость не указана (экспресс).\n#{from_to}"
                  end

      if i < max_lines
        i += 1
      else
        out << temp_arr
        i = 1
        temp_arr = []
      end
    end

    temp_arr << "Электричек на указанную дату нет." if temp_arr.size == 1 && temp_arr[0] == header && out.size == 0

    out << temp_arr

    out
  end
end
