# encoding: utf-8
require 'socket'

module CultomePlayer
    module SocketAdapter

        # The character sequence to send as command termination token.
        CMD_TERMINATOR_SEQ = '~~'

        # The character sequence to separate the components of a command.
        PARAM_TERMINATOR_SEQ = '::'

        # Connect to a socket in a host and register a data listener.
        #
        # @param host [String] The hostname or ip of the host running a socket server.
        # @param port [Integer] The number of port in the host where the server is listening for connections.
        # @param data_in_callback [Symbol] The name of the callback method to invoke when new data comes in the socket.
        def attach_to_socket(host, port, data_in_callback)
            raise 'Socket already attached!' if @socket

            @socket = TCPSocket.new(host, port)
            @listening_socket = true

            Thread.new do
                buffer = ""
                while(@listening_socket) do
                    begin
                        buffer << @socket.recv(1024)
                        split = buffer.split(CMD_TERMINATOR_SEQ)

                        buffer = buffer.end_with?(CMD_TERMINATOR_SEQ) ?  "" : split.pop

                        split.each do |cmd| 
                            send(data_in_callback, cmd)
                        end
                    rescue Exception => e
                        @listening_socket = false
                    end
                end
            end

            return @socket
        end

        # Unbind the socket and terminate the listeners thread.
        def close_socket
            @listening_socket = false
        end

        # Send a message through the socket
        #
        # @param params [Array<String>] The components of the command to send.
        def write_to_socket(*params)
            @socket.print "#{params.join(PARAM_TERMINATOR_SEQ)}#{CMD_TERMINATOR_SEQ}"
        end

        private

        # The queue of command readed in the socket and waiting to be processed.
        #
        # @return [Array] The list of command readed from the socket.
        def command_queue
            @command_queue ||= []
        end
    end
end
