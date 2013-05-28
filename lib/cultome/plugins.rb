require 'active_support/inflector'
require 'active_support'

module Plugins

    extend ActiveSupport::Autoload

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
        commands_path = "#{project_path}/lib/plugins"
        Dir.entries(commands_path).each do |file|
            if file =~ /\.rb\Z/
                file_name = file.gsub('.rb', '')
                class_name = file_name.classify

                # Lo cargamos...
                autoload class_name.to_sym, "plugins/#{file_name}"

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

            get_command_registry.each{|k,v|
                Plugins.command_registry.push k
                v[:command] = k
                Plugins.commands_help[k] = v
            } if respond_to?(:get_command_registry)

            get_listener_registry.each{|k,v|
                Plugins.listener_registry[k] << proc{|player, params| self.send v, player, params }
            }if respond_to?(:get_listener_registry)
        end

        def config
            Helper.master_config[self.to_s] ||= {}
        end
    end

    def cultome
        self
    end
end
