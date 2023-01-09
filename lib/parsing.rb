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
    trains = page.links_with(href: %r{^/station\.+})

    return 'Ошибка загрузки данных. Попробуйте еще раз' if schedule.empty? || trains.empty?

    out = []

    elements_quantity = schedule.size
    j = -2

    temp_arr = []
    temp_arr << "Расписание '#{ from }' -> '#{ to }' на #{ Date.parse(check_date).strftime("%d.%m.%Y") }:"
    i = 1

    (elements_quantity / 2).times do
      j = j + 2

      departure = Time.parse(schedule[j].text, Date.today)

      next if Date.parse(check_date) == Date.today && departure <= Time.now

      departure = departure.to_i
      arrival   = Time.parse(schedule[j + 1].text, Date.today).to_i
      arrival   = Time.parse(schedule[j + 1].text, Date.today + 1).to_i if departure > arrival

      time_to_drive = (arrival - departure) / 60
      time_to_drive = if time_to_drive > 60
                        '%dч %dмин' % time_to_drive.divmod(60)
                      else
                        "#{ (arrival - departure) / 60 }мин"
                      end

      if i < 11
        temp_arr << "Отпр: #{ schedule[j] }. Приб: #{ schedule[j+1] }. В пути: #{ time_to_drive }. Эл-ка: #{ trains[j] } -> #{ trains[j + 1] }"
        i += 1
      else
        out << temp_arr
        i = 1
        temp_arr = []
      end
    end

    out
  end
end
