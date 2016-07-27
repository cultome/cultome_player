module CultomePlayer
  module Plugins
    module KeyboardSpecialKeys
      def init_plugin_keyboard_special_keys
        Thread.new do
          start_cmd = "tail -f #{command_pipe}"
          IO.popen(start_cmd, "r+") do |pipe|
            begin
              line = pipe.gets
              # planchamos el prompt...
              display_over("")
              # ejecutamos el comando
              execute_interactively line
              # y luego lo regeneramos
              display_over c5(CultomePlayer::Interactive::PROMPT)
            end while true
          end # IO
        end # Thread
      end
    end # module
  end
end

