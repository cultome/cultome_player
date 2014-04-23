module CultomePlayer::Command
  module Processor
    def parse(user_input)
      tokens = identify_tokens(get_tokens(user_input))
      validate_command(:command, tokens)
      return CultomePlayer::Objects::Command.new(tokens.shift, tokens)
    end

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

    def identify_tokens(tokens)
      tokens.map do |token|
        id = guess_token_id(token)
        id.nil? ?  {type: :unknown, value: token} : get_token_value(token, id)
      end
    end

    def validate_command(type, tokens)
      current_format = get_command_format(type, tokens)
      # extraemos el primer token, que debe ser el comando
      cmd = tokens.first[:value]
      
      valid_format = semantics[cmd]
      if valid_format.nil?
        if plugins_respond_to?(cmd)
          valid_format = plugin_command_format(cmd)
        else
          raise 'invalid command:invalid action'
        end
      end
      return current_format =~ valid_format 
    end

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
      format = sintaxis[type].find do |stxs_elem| # ["action", "action parameters"]
        if stxs_elem.is_a?(String)
           # checamos si el numero de token en el comando corresponde
           # con el numer de tokens en la sintaxis
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
        max = sintaxis[type].max{|tk| tk.class == String ? tk.split.size: 0}
        if max.respond_to?(:split) && tokens.size > max.split.size
          format = max
        else
          raise 'invalid command:invalid command'
        end
      end

      return format
    end

  end
end
