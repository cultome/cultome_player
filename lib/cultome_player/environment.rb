require 'active_record'

module CultomePlayer
  module Environment
    def db_adapter
      'sqlite3'
    end

    def db_file
      File.expand_path 'spec/db.dat'
    end

    def db_log_path
      File.expand_path 'spec/db.log'
    end

    def file_types
      'mp3'
    end

    def with_connection(&db_logic)
      begin
        ActiveRecord::Base.connection_pool
      rescue Exception => e
        ActiveRecord::Base.establish_connection(
          adapter: db_adapter,
          database: db_file
        )
        ActiveRecord::Base.logger = Logger.new(File.open(db_log_path, 'a'))
      end

      ActiveRecord::Base.connection_pool.with_connection(&db_logic)
    end
  end
end
