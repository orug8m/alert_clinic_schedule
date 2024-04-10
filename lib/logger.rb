# frozen_string_literal: true

class Logger
  def self.create
    log = Logger.new(File.expand_path('./log/development.log'))
    log.level = Logger::INFO
    log
  end
end
