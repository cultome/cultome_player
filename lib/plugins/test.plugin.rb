module Plugins
    module Test
        def self.get_command_registry
            {
                kill: {
                help: "Delete from disk the current song", 
                params_format: "",
                usage: "A bried usage examples"
            }}
        end

		def self.get_listener_registry
			[:next, :prev]
		end

    end
end

