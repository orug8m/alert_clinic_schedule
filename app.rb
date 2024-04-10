# frozen_string_literal: true

require_relative 'lib/logger'
require_relative 'lib/reservation_checker'
require_relative 'lib/slack_configure'

def execute(division_code:, dates:)
  logger = Logger.create
  login_user = ENV.fetch('WEB_USERNAME', nil)
  logger.info("病院の予約チェックを開始: #{division_code}, #{dates}, user: #{login_user[0, 4]}...")

  dates_obj = dates.split(',').map { |d| Date.parse(d) }
  # 今日以降の日付のみに絞る
  dates_obj = dates_obj.map do |date_obj|
    date_obj if Date.today < date_obj
  end.compact

  raise '対象日がありません。' if dates_obj.empty?

  mached_dates = ReservationChecker.new(logger:, division_code:, target_dates: dates_obj).call
  puts("以下の日付が空いてます: #{mached_dates.join(',')}")
  notifi_slack(mached_dates:) unless mached_dates.empty?

  {
    statusCode: 200,
    body: {
      message: 'complete'
    }.to_json
  }
rescue StandardError => e
  logger.error("失敗しました. #{e}")
  {
    statusCode: 400,
    body: {
      message: e.message,
      backtrace: e.backtrace.join("\n")
    }.to_json
  }
end

# @param mached_dates [Array<Str>] MM-DDの配列
def notifi_slack(mached_dates:)
  client = Slack::Web::Client.new
  client.chat_postMessage(
    channel: '#小児科_予約可能_通知',
    text: "以下の日付が空いてます: #{mached_dates.join(',')}",
    as_user: true
  )
end

division_code = ENV.fetch('DIVISION_CODE', nil)
dates = ENV.fetch('DATES', nil)

execute(division_code:, dates:)
