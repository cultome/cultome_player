require 'active_support/inflector'

module Plugins

    def self.commands_help
        @commands_help ||= {}
    end

    def self.listener_registry
        @listener_registry ||= Hash.new{|h,k| h[k] = []}
    end

    def self.command_registry
        @command_registry ||= []
    end

    def self.included(base)
        puts "$######## #{self} PLUGIN PARENT INCLUDED IN #{base}"
        commands_path = "#{project_path}/lib/plugins"
        Dir.entries(commands_path).each do |file|
            if file =~ /\.plugin\.rb\Z/
                file_name = file.gsub('.plugin.rb', '')
                class_name = file_name.classify

                # Lo cargamos...
                autoload class_name.to_sym

                class_const = "Plugins::#{class_name}".constantize

                # le agregamos el metodo included...
                class << class_const
                    include ClassMethods
                end

                # lo incluimos en la clase base
                base.send :include, class_const
            end
        end
    end

    module ClassMethods
        def included(base)
            puts "######## #{self} PLUGINS CHILDREN INCLUDED IN #{base}"
            cmd_regs = get_command_registry if respond_to?(:get_command_registry)
            listener_regs = get_listener_registry if respond_to?(:get_listener_registry)

            cmd_regs.each{|k,v|
                Plugins.command_registry.push k
                Plugins.listener_registry[k] << nombre_metodo
                v[:command] = k
                Plugins.commands_help[k] = v
            } unless cmd_regs.nil?

            listener_regs.each{|k,v|
                Plugins.listener_registry[k] << command
            } unless listener_regs.nil?
        end
    end
end
