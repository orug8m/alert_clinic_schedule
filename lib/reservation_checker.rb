# frozen_string_literal: true

require 'selenium-webdriver'
require 'date'
require 'uri'

require_relative 'logger'

# チェッカー
class ReservationChecker
  def initialize(division_code:, target_dates:)
    @division_code = division_code
    @target_dates = target_dates
    @logger = Logger.create
    set_browser_options
    start_browser
    login
  end

  # @return [Array<Str>] MM-DDの配列を返す
  def call
    puts('予約状況を確認します。')
    @driver.navigate.to "https://medicalpass.jp/departments/#{@division_code}/reservations/select_date"

    puts "https://medicalpass.jp/departments/#{@division_code}/reservations/select_date"

    sleep 3

    # table_view内のaタグのhref属性を取得
    links = []
    @driver.find_elements(class: 'table_view').each do |item|
      item.find_elements(tag_name: 'a').each { |a| links << a.attribute('href') }
    end

    sleep 3

    # hrefからtarget_dateの値を抽出して配列に格納
    available_dates = links.map do |link|
      target_date = URI.parse(link).query.match(/target_date=(\d{4}-\d{2}-\d{2})/)[1]
      Date.parse(target_date)
    end

    mached_dates = @target_dates & available_dates
    puts('予約状況の確認が完了しました。')
    close_browser
    mached_dates.map { |d| d.strftime('%m-%d') }
  end

  private

  def set_browser_options
    @options = Selenium::WebDriver::Chrome::Options.new
    @options.add_argument('--headless')
    @options.add_argument('--disable-gpu')
    @options.add_argument('--disable-dev-shm-usage')
    @options.add_argument('--disable-setuid-sandbox')
    @options.add_argument('--single-process')
    @options.add_argument('--no-sandbox')
    @options.add_argument('--encoding=UTF-8')
    @options.add_argument('--disable-ipv6')
    @options.add_argument('--lang=ja-JP')
    @options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.81 Safari/537.36')
    @options.add_preference(:pageLoadStrategy, 'eager')
  end

  def start_browser
    puts('ブラウザを起動します。')
    logger = Selenium::WebDriver.logger
    logger.ignore(:logger_info)
    @driver = Selenium::WebDriver.for :chrome, options: @options
    @wait = Selenium::WebDriver::Wait.new(timeout: 120)
  rescue StandardError => e
    @logger.error("ブラウザの起動に失敗しました。#{e}")
  end

  def login
    puts('ログイン処理を開始します。')
    @driver.navigate.to 'https://medicalpass.jp/users/login'

    username_field = @driver.find_element(name: 'user[email]')
    username_field.send_keys(ENV.fetch('WEB_USERNAME'))

    password_field = @driver.find_element(name: 'user[password]')
    password_field.send_keys(ENV.fetch('WEB_PASSWORD'))

    login_button = @driver.find_element(name: 'commit')
    login_button.click

    sleep 5

    cookies = @driver.manage.all_cookies
    cookies.each do |cookie|
      @driver.manage.add_cookie(cookie)
    end

    puts('ログイン処理が完了しました。')
  rescue StandardError => e
    @logger.error("ログイン処理に失敗しました。#{e}")
  end

  def close_browser
    @driver.quit
    puts('ブラウザを終了しました。')
  rescue StandardError => e
    @logger.error("ブラウザの終了に失敗しました。#{e}")
  end
end
