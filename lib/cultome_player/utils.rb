require 'active_record'

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

    # Define the 15 colors allowed in my console scheme
    (1..15).each do |idx|
      define_method :"c#{idx}" do |str|
        str
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
