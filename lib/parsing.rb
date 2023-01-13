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
    header = "Расписание #{ from } -> #{ to } на #{ Date.parse(check_date).strftime("%d.%m.%Y") }:"

    temp_arr << header

    parsed_doc.each do |line|
      # Удаляем лишнюю строку
      next if !line.match?(/(?:[a-zA-Zа-яА-Я])(\d{2}.м)/){ $1 }

      arrival = line.match(/\A\d{2}:\d{2}/).to_s
      departure = line.match(/(?<!^)(\d{2}:\d{2})/).to_s
      time_to_drive = line.match(/(?:[a-zA-Zа-яА-Я])(\d{2}.м)/){ $1 }[0..-3]

      from_to = line.match(/(?:м)([А-ЯЁ].+)/){ $1 }
      from_to = from_to[0..-3].gsub(/(\d+$)/, '') if from_to[0..-3].match?(/([А-ЯЁа-яё]{2,})(?:\d+$)/)

      price = line.match(/(\d+)(.₽\z)/){ $1 } if line.match?(/(\d+)(.₽\z)/)

      temp_arr << if price
                    "Отпр: #{ arrival }. Приб: #{ departure }. В пути: #{ time_to_drive }мин. Стоимость: #{price}руб.\n #{from_to}"
                  else
                    "Отпр: #{ arrival }. Приб: #{ departure }. В пути: #{ time_to_drive }мин.\n#{from_to}"
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
