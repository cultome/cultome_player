require 'socket'

module CultomePlayer
    module SocketAdapter
        CMD_TERMINATOR_SEQ = '~~'
        PARAM_TERMINATOR_SEQ = '::'

        def attach_to_socket(host, port, data_in_callback)
            raise 'Socket already attached!' if @socket

            @socket = TCPSocket.new(host, port)
            Thread.new do
                buffer = ""
                while(true) do
                    buffer << @socket.recv(1024)
                    split = buffer.split(CMD_TERMINATOR_SEQ)

                    buffer = buffer.end_with?(CMD_TERMINATOR_SEQ) ?  "" : split.pop

                    split.each do |cmd| 
                        send(data_in_callback, cmd)
                    end
                end
            end

            return @socket
        end

        def write_to_socket(*params)
            @socket.print "#{params.join(PARAM_TERMINATOR_SEQ)}#{CMD_TERMINATOR_SEQ}"
        end
 
        private

        def command_queue
            @command_queue ||= []
        end
    end
end
