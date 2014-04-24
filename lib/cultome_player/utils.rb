require 'active_record'
require 'colorize'

module CultomePlayer
  module Utils

    # Check if a string value can be a positive boolean value.
    #
    # @param value [String] String to check if can be a positive boolean value.
    # @return [Boolean] True if value is a positive boolean value. False otherwise.
    def is_true_value?(value)
      /true|yes|on|y|n|s|si|cierto/ === value 
    end

    # Print a string into stdout (not STDOUT) and finish with a newline character.
    #
    # @param msg [String] The value to be printed.
    # @return [String] The value printed.
    def display(msg)
      stdout.puts msg
      return msg
    end

    # Print a string into stdout (not STDOUT) but before insert a carriage return and dont append a newline character at the end.
    #
    # @param msg [String] The value to be printed.
    # @return [String] The value printed.
    def display_over(msg)
      stdout.print "\r#{msg}"
      return msg
    end

    # Define the 15 colors allowed in my console scheme
    (1..18).each do |idx|
      define_method :"c#{idx}" do |str|
        case idx
          when 1 then str.colorize(:blue)
          when 2 then str.colorize(:black)
          when 3 then str.colorize(:red)
          when 4 then str.colorize(:green)
          when 5 then str.colorize(:yellow)
          when 6 then str.colorize(:blue)
          when 7 then str.colorize(:magenta)
          when 8 then str.colorize(:cyan)
          when 9 then str.colorize(:white)
          when 10 then str.colorize(:default)
          when 11 then str.colorize(:light_black)
          when 12 then str.colorize(:light_red)
          when 13 then str.colorize(:light_green)
          when 14 then str.colorize(:light_yellow)
          when 15 then str.colorize(:light_blue)
          when 16 then str.colorize(:light_magenta)
          when 17 then str.colorize(:light_cyan)
          when 18 then str.colorize(:light_white)
          else str
        end
      end
    end

    # Arrange an array of string into single string arranged by columns separed by an inner border.
    #
    # @param cols [List<String>] The strings to be arranged.
    # @param widths [List<Integer>] The width of the columns.
    # @param border [Integer] The width of the inner borders.
    # @return [String] The string representation of columns.
    def arrange_in_columns(cols, widths, border)
      row = ""
      idxs = cols.collect{|c| 0 }
      
      while cols.zip(idxs).any?{|col| col[0].length > col[1] }
        cols.each.with_index do |col, idx|
          slice_width = widths[idx]
          
          slice = col.slice(idxs[idx], slice_width) || "" # sacamos el pedazo de la columna
          row << slice.ljust(slice_width) # concatenamos a la fila
          idxs[idx] += slice_width # recorremos el indice
          row << " " * border # agregamos el border de la derecha
        end

        row = row.strip << "\n" # quitamos el ultimo border
      end

      return row.strip # quitamos el ultimo salto de linea
    end

    # Capture and dispose the standard output sended inside the block provided.
    #
    # @return [String] The swallowed data.
    def swallow_stdout
      s = StringIO.new
      oldstd = $stdout
      $stdout = s
      yield
      return s.string
    ensure
      $stdout = oldstd
    end

    # Provides a wrapper for database connection.
    #
    # @param db_block [Block] The block to be executed inside a database connection.
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
