require 'active_record'

module CultomePlayer
  module Utils
    def is_true_value?(value)
      /true|yes|on|y|n|s|si|cierto/ === value 
    end

    # Capture and dispose the standard output sended inside the block provided.
    def swallow_stdout
      s = StringIO.new
      oldstd = $stdout
      $stdout = s
      yield
      s.string
    ensure
      $stdout = oldstd
    end

    def with_connection(&db_logic)
      begin
        ActiveRecord::Base.connection_pool
      rescue Exception => e
        ActiveRecord::Base.establish_connection(
          adapter: db_adapter,
          database: db_file
        )
        ActiveRecord::Base.logger = Logger.new(File.open(db_log_file, 'a'))
      end

      ActiveRecord::Base.connection_pool.with_connection(&db_logic)
    end
  end
end
