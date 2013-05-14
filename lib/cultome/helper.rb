require 'active_support/inflector'
require 'yaml'
require 'mp3info'

# Utility module with shared functions across the project.
module Helper
	CONFIG_FILE = "config.yaml"

	# Return the path to the config file
	def master_config
		@master_config ||= YAML.load_file(CONFIG_FILE)
	end

	# Search and require the jar files required by the underlying music player.
	#
	# @return [List<String>] A list with the names of the required jar files.
	def require_jars
		jars_path = "#{project_path}/jars"
		Dir.entries(jars_path).select{|jar| 
			require "#{jars_path}/#{jar}" if jar =~ /.jar\Z/
		}
	end

	# Extract the ID3 tag information from a mp3 file.
	#
	# @param file_path [String] The full path to a mp3 file.
	# @return [Hash] With the keys: :name, :artist, :album, :track, :duration, :year and :genre. nil if something is wrong.
	def extract_mp3_information(file_path)
		info = nil
		begin
			Mp3Info.open(file_path) do |mp3|
				info = {
					name: mp3.tag.title,
					artist: mp3.tag.artist,
					album: mp3.tag.album,
					track: mp3.tag.tracknum,
					duration: mp3.length,
					year: mp3.tag1["year"],
					genre: mp3.tag1["genre_s"]
				}
			end

			if info[:name].nil?
				info[:name] = file_path.split('/').last
			end

			return polish(info)
		rescue
			display c2("The file '#{file_path}' could not be added")
			return nil
		end
	end

	# Convert an amount of seconds to its representation mm:ss
	#
	# @param seconds [Integer] The number of seconds to convert.
	# @return [String] A time representation of mm:ss
	def to_time(seconds)
		"#{(seconds/60).to_s.rjust(2, '0')}:#{(seconds%60).to_s.rjust(2, '0')}"
	end

	# Return the path to the base of the instalation.
	#
	# @return [String] The path to the base of the instalation.
	def project_path
		@_project_path ||= File.expand_path(File.dirname(__FILE__) + "/../..")
	end

	# Return the path to the migrations folder.
	#
	# @return [String] The path to the migrations folder.
	def migrations_path
		"#{ project_path }/db/migrate"
	end

	# Return the path to the logs folder.
	#
	# @return [String] The path to the logs folder.
	def db_logs_folder_path
		"#{ project_path }/logs"
	end

	# Return the path to the log file.
	#
	# @return [String] The path to the log file.
	def db_log_path
		"#{db_logs_folder_path}/db.log"
	end

	# Return the db adapter name used.
	#
	# @return [String] The db adapter name.
	def db_adapter
		ENV['db_adapter'] || 'jdbcsqlite3'
	end

	# Return the path to the db data file.
	#
	# @return  [String] The path to the db data file.
	def db_file
		"#{project_path}/db_cultome.dat"
	end

	def define_color_palette
		if @color_palette.nil?
			@color_palette = @config["color_palette"]
			if @color_palette.nil?
				@color_palette = [
					:black,			# c1
					:red,			# c2
					:green,			# c3
					:yellow,		# c4
					:blue,			# c5
					:magenta,		# c6
					:cyan,			# c7
					:white,			# c8
					:default,		# c9
					:light_red,		# c10
					:light_green,	# c11
					:light_yellow,	# c12
					:light_blue,	# c13
					:light_magenta,	# c14
					:light_cyan,	# c15
					:light_white,	# c16
				]
				@config["color_palette"] = @color_palette
			end
		end

		@color_palette.each_with_index do |color, idx|
			Helper.class_eval do
				define_method "c#{idx+1}".to_sym do |str|
					str.send(color)
				end
			end
		end
	end

	private

	# Clean and format the track information.
	# @param info [Hash] With the keys: :name, :artist, :album, :track, :duration, :year and :genre.
	# @return [Hash] The same hash but with polished values.
	def polish(info)
		[:name, :artist, :album].each{|k| info[k] = info[k].downcase.strip.titleize unless info[k].nil? }
		[:track, :year].each{|k| info[k] = info[k].to_i if info[k] =~ /\A[\d]+\Z/ }
		info[:duration] = info[:duration].to_i

		info
	end
end

# abrimos algunas clases con propositos utilitarios
class Array
	def to_s
		idx = 0
		self.collect{|e| "#{( idx += 1 ).to_s.rjust(4)} #{e}" }.join("\n")
	end
end

class String
	def blank?
		self.nil? || self.empty?
	end
end
