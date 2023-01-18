require 'dotenv/load'
require 'telegram/bot'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require_relative 'lib/bot'
require_relative 'lib/parsing'

URL = 'https://www.tutu.ru/prigorod/'

STATIONS = ['Железнодорожная', 'Ольгино', 'Нижегородская', 'Серп и Молот', 'Москва Курская']

BUTTONS_ARR1, BUTTONS_ARR2 = STATIONS.each_slice((STATIONS.size / 2.0).round).to_a

# Вывод расписания по 10 строк
MAX_LINES = 10

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

bot=Bot.new(stations: STATIONS, buttons_arr1: BUTTONS_ARR1, buttons_arr2: BUTTONS_ARR2, max_lines: MAX_LINES, bot_token: tg_bot_token, url: URL)

bot.main_method
