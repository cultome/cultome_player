module CultomePlayer::Command
  module Language

    # Define the sintaxis of the player language.
    #
    # @return [Hash] With the keys :command, :parameters, :actions, :param
    def sintaxis
      # <command>    : <action> | <action> <parameters>
      # <action>     : literal
      # <parameters> : <param> | <param> <parameters>
      # <param>      : literal | criteria | number | object | path | bubble
      {
        command: ["action", "action parameters"],
        parameters: ["param", "param parameters"],
        action: [:literal],
        param: [:literal, :criteria, :number, :object, :path, :boolean, :bubble],
      }
    end

    # Returns the semantics of the builtin commands.
    #
    # @note The first literal in regex is the command itself.
    # @return [Hash<String, Regex>] The key is the command name and the regex its format.
    def semantics
      {
        "play" => /^literal(literal|number|criteria|object|[\s]+)*$/,
        "show" => /^literal(number|object|[\s]+)*$/,
        "search" => /^literal(literal|criteria|[\s]+)+$/,
        "enqueue" => /^literal(literal|number|criteria|object|[\s]+)+$/,
        "connect" => /^literal ((literal)|(path) bubble (literal))$/,
        "disconnect" => /^literal (literal)$/,
        "stop" => /^literal[\s]*$/,
        "pause" => /^literal (boolean)$/,
        "prev" => /^literal[\s]*$/,
        "next" => /^literal[\s]*$/,
        "quit" => /^literal[\s]*$/,
        "ff" => /^literal(number|[\s]+)*$/,
        "fb" => /^literal(number|[\s]+)*$/,
        "shuffle" => /^literal[\s]+(boolean)$/,
        "repeat" => /^literal[\s]*$/,
      }
    end

    # Return the token identities.
    #
    # @return [List<Hash>] The has contains the type of the token and their format.
    def token_identities
      [
        {type: :bubble, identity: /^(=>|->)$/},
        {type: :object, identity: /^@([\w\d]+)$/},
        {type: :number, identity: /^([\d]+)$/},
        {type: :criteria, identity: /^([\w]+):([\d\w\s]+)$/, captures: 2, labels: [:criteria, :value]},
        {type: :path, identity: /^(['"]?(?:\/|~\/)[\/\w\d\s.]+)["']?$/},
        {type: :boolean, identity: /^(on|off|yes|false|true|si|no|y|n|s|ok)$/},
        {type: :literal, identity: /^([\w\d\s]+)$/},
      ]
    end

  end
end
