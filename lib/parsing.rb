class Parsing
  def initialize(url:)
    @url ||= url
  end

  def schedule(from:, to:, check_date:)
    mechanize = Mechanize.new

    page = mechanize.get(@url)

    form = page.forms[3]

    form['st1']  = from
    form['st2']  = to
    form['date'] = check_date

    page = form.submit

    schedule = page.links_with(href: %r{^/view\.+})
    trains = page.links_with(href: %r{^(https://\.+)|(/station\.+)})

    return 'Ошибка загрузки данных. Попробуйте еще раз' if schedule.empty? || trains.empty?

    out = []

    elements_quantity = schedule.size
    j = -2

    temp_arr = []
    header = "Расписание #{ from } -> #{ to } на #{ Date.parse(check_date).strftime("%d.%m.%Y") }:"
    temp_arr << header
    i = 1

    (elements_quantity / 2).times do
      j = j + 2

      if check_date == Date.today.to_s
        departure = Time.parse(schedule[j].text, Date.today)

        # Следующий день, если время отправления >00:00 и <03:00
        departure = Time.parse(schedule[j].text, Date.today + 1) if departure > Time.parse(Date.today.to_s) && departure < Time.parse('03:00', Date.today)

        if departure <= Time.now
          next if out.include?(temp_arr)

          out << temp_arr
        end

        departure = departure
        arrival   = Time.parse(schedule[j + 1].text, Date.today)
        arrival   = Time.parse(schedule[j + 1].text, Date.today + 1) if departure > arrival

      else
        departure = Time.parse(schedule[j].text, Date.today + 1)

        departure = departure
        arrival   = Time.parse(schedule[j + 1].text, Date.today + 1)
      end

      time_to_drive = (arrival - departure) / 60
      time_to_drive = if time_to_drive > 60
                        '%dч %dмин' % time_to_drive.divmod(60)
                      else
                        "#{ (arrival - departure) / 60 }мин"
                      end

      temp_arr << "Отпр: #{ schedule[j] }. Приб: #{ schedule[j+1] }. В пути: #{ time_to_drive }.\nЭл-ка: #{ trains[j] } -> #{ trains[j + 1] }."

      if i < 11
        i += 1
      else
        out << temp_arr
        i = 1
        temp_arr = []
      end
    end

    if temp_arr.size == 1 && temp_arr[0] == header && out.size == 0
      temp_arr << "Электричек на указанную дату нет."
      out << temp_arr
    else
     out << temp_arr 
    end

    out
  end
end
