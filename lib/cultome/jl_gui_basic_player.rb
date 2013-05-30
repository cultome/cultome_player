require 'java'
require 'cultome/helper'

jars_path = "#{Cultome::Helper.project_path}/jars"
Dir.entries(jars_path).select{|jar| 
    require "#{jars_path}/#{jar}" if jar =~ /.jar\Z/
}

java_import 'Player'
