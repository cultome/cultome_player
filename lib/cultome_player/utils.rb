require 'active_record'

module CultomePlayer
  module Utils
    def is_true_value?(value)
      /true|yes|on|y|n|s|si|cierto/ === value 
    end

    def display(msg)
      stdout.puts msg
    end

    (1..15).each do |idx|
      define_method :"c#{idx}" do |str|
        str
      end
    end

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
