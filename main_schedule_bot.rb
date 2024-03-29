require 'dotenv/load'
require 'telegram/bot'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require_relative 'lib/bot'
require_relative 'lib/parsing'

URL = 'https://www.tutu.ru/prigorod/'

STATIONS_BUTTONS = [[text: 'Железнодорожная'], [text: 'Ольгино'], [text: 'Нижегородская'], [text: 'Серп и Молот'], [text: 'Москва Курская']]
# Отдельный список названий, чтобы сверяться, если название станции будет набрано на клавиатуре, а не нажатием на кнопку
STATIONS_LIST1 = ['железнодорожная', 'ольгино', 'нижегородская', 'серп и молот']
STATIONS_LIST2 = ['москва курская', 'москва', 'курская']

buttons_arr1, buttons_arr2 = STATIONS_BUTTONS.each_slice((STATIONS_BUTTONS.size / 2.0).round).to_a
BUTTONS_ARR1 = buttons_arr1.flatten
BUTTONS_ARR2 = buttons_arr2.flatten

# Количество выводимых строк в расписании
MAX_LINES = 8

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

bot=Bot.new(max_lines: MAX_LINES, bot_token: tg_bot_token, url: URL)

bot.main_method
