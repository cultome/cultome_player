# encoding: UTF-8

require 'active_record'
require 'logger'

ActiveRecord::Base.logger = Logger.new('logs/db.log')

ActiveRecord::Base.establish_connection(
    adapter: "jdbcsqlite3",
    database: "dev.sql"
)