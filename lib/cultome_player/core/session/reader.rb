require 'readline'

module CultomePlayer::Core::Session::Reader
  # Display a prompt and read user input.
  #
  # @param prompt [String] The message to display to user for arcking for input.
  # @return [String] The user input readed.
  def read_command(prompt)
    input = command_reader.readline(c5(prompt), true)

    # evitamos que comando consecutivos repetidos o vacios queden en el historial
    if input.empty?
      command_reader::HISTORY.pop
    elsif command_reader::HISTORY.to_a.reverse[1] == input
      command_reader::HISTORY.pop
    end

    return input
  end

  # Lazy getter for readline object.
  #
  # @return [Readline] The readline object
  def command_reader
    return Readline if @command_reader_initialized

    Readline.completion_append_character = ""
    Readline.basic_word_break_characters = Readline.basic_word_break_characters.delete("@")
    Readline.completion_proc = completion_proc
    @command_reader_initialized = true
    return Readline
  end

  private

  def completion_proc
    proc do |word|
      if Readline.line_buffer.empty?
        # linea en blanco y no sabe los comandos
        options = semantics.keys #return
      else
        tks = Readline.line_buffer.split
        if tks.length == 1
          options = complete_action(tks[0], word)
        elsif tks.length > 1
          options = complete_parameter(tks[0], word)
        end
      end

      options = [] if options.nil?
      options << word if options.empty?
      options << " " if options.all?{|o| o.start_with?("<")}
      options # final return
    end # proc
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

  def complete_parameter(cmd, word)
    options = get_command_param_options(cmd, word) do
      # esta acompletando un parametro
      if word.start_with?("/") || word.start_with?("~/")
        expanded_path = File.expand_path(word)
        expanded_path += "/" if File.directory?(expanded_path)
        Dir[expanded_path + "*"].grep(/^#{Regexp.escape(expanded_path)}/).collect{|d| "#{d}/"}
      elsif word.start_with?("@")
        %w{@playlist @current @history @queue @search @song @artist @album @drives @artists @albums @genres @library @recently_added @recently_played @most_played @less_played @populars}.grep(/^#{word}/)
      end
    end
  end

  def complete_action(cmd, word)
    # escribio una parabra..
    get_command_param_options(cmd, word) do
      # incompleta! require acompletar el action actual
      semantics.keys.grep(/^#{Regexp.escape(Readline.line_buffer)}/).collect{|s| "#{s} "}
    end
  end
end
