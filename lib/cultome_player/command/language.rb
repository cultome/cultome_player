module CultomePlayer::Command
  module Language
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

    def semantics
      {
        "play" => /^literal(literal|number|criteria|object|[\s]+)*$/,
        "show" => /^literal(number|object|[\s]+)*$/,
        "search" => /^literal(literal|criteria|[\s]+)+$/,
        "enqueue" => /^literal(literal|number|criteria|object|[\s]+)+$/,
        "connect" => /^literal ((literal)|(path) bubble (literal))$/,
        "stop" => /^literal[\s]*$/,
        "pause" => /^literal (boolean)$/,
        "prev" => /^literal((literal)|[\s]+)*$/,
        "next" => /^literal[\s]*$/,
        "shuffle" => /^literal[\s]+(boolean)$/,
      }
    end

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
