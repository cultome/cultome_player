# encoding: utf-8
module CultomePlayer::Extras
  module CommandAlias

    # Include de command alias and register a listener for event invalid_command_error.
    def self.included(base)
      CultomePlayer::Player.command_registry << :alias
      CultomePlayer::Player.command_help_registry[:alias] = {
        help: "Create an alias for one or many commands", 
        params_format: "<literal> => <literal>",
        usage: <<-HELP
Create a synonimous for a "command string", where "command string" is a valid sequence of commands. The command string can declare placeholder that will be filled with parameters provided by user.

Some usages examples includes the followings:

If you miss Vim you can alias the command quit with the string 'q!'. So the next time you want to close the player just type 'q!'.
    * alias quit => q!

If you are like me, and you like to hear a song that you know when you search it always appears in the same position in the results list, you can make a "macro" to play it. This way you preserve you current playlist and hear you song anytime.
    * alias search_and_play => "search %1 | play %2"
With this little "macro", you are declaring a placeholder that will be replaced with whaterever the user pass as parameter with your alias. For example
    * search_and_play space 2
Will be converted to
    * search space | play 2
You can declared as many place holders as you want. The rules of players' parameters are always presents, so if, for example, space characters exist in the command or command's parameter, this must be wrapped by " or '.

        HELP
      }

      CultomePlayer::Player.register_event_listener(:invalid_command_error, :search_for_command_alias)

    end

    # Create a persistent alias.
    #
    # @param params [List<Hash>] With parsed literals information.
    def alias(params=[])
      raise "Incorrect parameters format. Type 'help alias' for more information." if params.size != 2
      raise "Incorrect parameters format. Type 'help alias' for more information." unless params.all?{|a| a[:type] == :literal || a[:type] == :unknown }

      alias_name = params[0][:value]
      alias_value = params[1][:value]

      registered_aliases[alias_name] = alias_value

      return c4("Alias '#{alias_name}' was successfuly registered!")
    end

    # Accessor for registered aliases, persistend and no-yet persisted.
    #
    # @return [Hash] With the key being the alias and the values their respective tranlations.
    def registered_aliases
      extras_config['aliases'] ||= {"exit" => "quit"}
    end

    private

    # Invoked when a player exception is throwed
    #
    # @param user_input [String] The user input that cause  the exception.
    def search_for_command_alias(user_input)
      # separamos el comando
      split = user_input.split(' ')
      raise 'Invalid command' if split[0].nil? || registered_aliases[split[0]].nil?

      translated = registered_aliases[split[0]].clone

      if split.size > 1
        1.upto(split.size - 1) do |c|
          translated.gsub!(/\%#{c}/, split[c])
        end
      end

      #ex.add_attribute(:displayable, false)

      ret_value = execute translated
      return ret_value.last if ret_value.respond_to?(:last)
      return ret_value
    end
  end
end
