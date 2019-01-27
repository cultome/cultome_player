module CultomePlayer::Core::Session::Processor

  # Parse a user input into a command
  #
  # @param user_input [String] The user input to be parsed.
  # @return [Command] The parsed command.
  def parse(user_input)
    return user_input.split("&&").collect do |usr_in|
      tokens = identify_tokens(get_tokens(usr_in.strip))
      validate_command(:command, tokens)
      CultomePlayer::Core::Objects::Command.new(tokens.shift, tokens)
    end
  end

  # Split the user input into tokens.
  #
  # @param user_input [String] The user input.
  # @return [List<String>] The detected tokens.
  def get_tokens(user_input)
    tokens = []
    token = ""
    capturing_string = false

    user_input.each_char do |char|
      case char
      when /[\d\w\/:@]/
        token << char
      when /["']/
        capturing_string = !capturing_string
      when /[\s]/
        if capturing_string
          token << char
        else
          tokens << token
          token = ""
        end
      else
        token << char
      end # case
    end # each

    tokens << token unless token.empty?
    raise "invalid command:unclosed string" if capturing_string

    return tokens
  end

  # Identify detected tokens.
  #
  # @param tokens [List<String>] The detected tokens.
  # @return [List<Hash>] The hash contains keys :type and :value.
  def identify_tokens(tokens)
    tokens.map do |token|
      id = guess_token_id(token)
      id.nil? ?  {type: :unknown, value: token} : get_token_value(token, id)
    end
  end

  # Check that a the tokens identifed correspond to a player command.
  #
  # @param type [Symbol] The language structure you try to match.
  # @param tokens [List<Hash>] The list of tokens identified.
  # @return [Boolean] True if the user command match with a player command format.
  def validate_command(type, tokens)
    current_format = get_command_format(type, tokens)
    # extraemos el primer token, que debe ser el comando
    cmd = tokens.first[:value]

    valid_format = semantics[cmd]
    raise 'invalid command:invalid action' if valid_format.nil?
    return current_format =~ valid_format
  end

  # Creates a string representation of the command prototype.
  #
  # @param type [Symbol] The Language structure you try to match.
  # @param tokens [List<Hash>] The Language structure you try to match.
  # @return [String] The string representation of the command prototype.
  def get_command_format(type, tokens)
    format = guess_command_format(type, tokens)

    return format if format.class == Symbol

    langs = format.split
    # partimos el formato y validamos cada pedazo
    tks = tokens.clone

    cmd_format = ""
    while !langs.empty? do
      # extraemos el primer elemento del formato
      lang = langs.shift

      if langs.empty?
        # volvemos a validar con el nuevo elemento del lenguaje
        cmd_format << " " << get_command_format(lang.to_sym, tks).to_s
      else
        tk = tks.shift
        cmd_format << " " << get_command_format(lang.to_sym, tk).to_s
      end
    end
    # limpiamos el formato final
    return cmd_format.strip.gsub(" ", " ")
  end

  private

  def guess_token_id(token)
    token_identities.find do |tok_id|
      token =~ tok_id[:identity]
    end
  end

  def get_token_value(token, id)
    captures = id[:captures] || 1
    labels = id[:labels] || [:value]

    token_info = {type: id[:type]}

    token =~ id[:identity]
    (1..captures).to_a.zip(labels).each do |idx, label|
      token_info[label] = eval("$#{idx}")
    end

    return token_info
  end

  def guess_command_format(type, tokens)
    # buscamos el formato que tenga mas matches con los parametros
    format = sintax[type].find do |stxs_elem| # ["action", "action parameters"]
      if stxs_elem.is_a?(String)
        # checamos si el numero de token en el comando corresponde
        # con el numer de tokens en la sintax
        stxs_elem.split.size >= tokens.size # ej. "play 1 2" === "action paramters"
      elsif stxs_elem.is_a?(Symbol)
        if tokens.is_a?(Hash)
          tokens[:type] == stxs_elem
        elsif tokens.is_a?(Array) && tokens.size == 1
          tokens.first[:type] == stxs_elem
        else
          false
        end
      else
        raise 'invalid command:invalid command format'
      end
    end

    if format.nil?
      max = sintax[type].max{|tk| tk.class == String ? tk.split.size: 0}
      if max.respond_to?(:split) && tokens.size > max.split.size
        format = max
      else
        raise 'invalid command:invalid command'
      end
    end

    return format
  end

end
