require 'readline'

module CultomePlayer::Command
  module Reader

    def read_command(prompt)
      command_reader.readline(prompt, true)
    end

    def get_command_param_options(cmd, word)
      if word.empty?
        # completa! mostramos los parametros disponibles para el comando
        if semantics.keys.include?(cmd)
          # mostramos las opciones de parametros IFF acepta parametros
          params = semantics[cmd].source.gsub(/^\^literal/, '').gsub(/\[\\s\][+*]/, "").gsub(/[()*$]/, '')

          params.split(/[| ]/).collect{|p| "<#{p}>"} unless params.empty?
        end
      else
        yield if block_given?
      end
    end

    def command_reader
      return Readline if @command_reader_initialized

      Readline.completion_append_character = ""
      Readline.basic_word_break_characters = Readline.basic_word_break_characters.delete("@")
      Readline.completion_proc = completion_proc
      @command_reader_initialized = true
      return Readline
    end

    def completion_proc
      proc do |word|
        if Readline.line_buffer.empty?
          # linea en blanco y no sabe los comandos
          options = semantics.keys #return
        else
          tks = Readline.line_buffer.split
          if tks.length == 1
            # escribio una parabra..
            options = get_command_param_options(tks[0], word) do
              # incompleta! require acompletar el action actual
              semantics.keys.grep(/^#{Regexp.escape(Readline.line_buffer)}/).collect{|s| "#{s} "}
            end
          elsif tks.length > 1
            options = get_command_param_options(tks[0], word) do
              # esta acompletando un parametro
              if word.start_with?("/") || word.start_with?("~/")
                expanded_path = File.expand_path(word)
                expanded_path += "/" if File.directory?(expanded_path)
                Dir[expanded_path + "*"].grep(/^#{Regexp.escape(expanded_path)}/).collect{|d| "#{d}/"}
              elsif word.start_with?("@")
                %w{@library @search @playlist @history @queue @song @artist @album @drives}.grep(/^#{word}/)
              end
            end
          end
        end

        options = [] if options.nil?
        options << word if options.empty?
        options << " " if options.all?{|o| o.start_with?("<")}
        options # final return
      end # proc
    end

  end
end
