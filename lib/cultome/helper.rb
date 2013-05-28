require 'active_support/inflector'
require 'yaml'
require 'mp3info'
require 'colorize'
require 'active_record'
require 'logger'

# Utility module with shared functions across the project.
module Helper

	CONFIG_FILE_NAME = "config.yml"

    # Return the path to the config file
    #
    # @return [String] The path to the config file
    def self.master_config
        return @master_config if @master_config

        begin
            @master_config = YAML.load_file(config_file)

            unless @master_config
                @master_config = create_basic_config_file
            end
        rescue Exception => e
            @master_config = create_basic_config_file
        end
        
        return @master_config
    end

    def self.create_basic_config_file
        File.open(config_file, 'w'){|f| YAML.dump({'core' => {'prompt' => 'cultome> '}}, f)}
        YAML.load_file(config_file)
    end

	# Create a context with a managed connection from the pool. The block passed will be
	# inside a valid connection.
	#
	# @param db_logic [Block] The logic that require a valid db connection.
	def with_connection(&db_logic)
		begin
			ActiveRecord::Base.connection_pool
		rescue Exception => e
			ActiveRecord::Base.establish_connection(
				adapter: db_adapter,
				database: db_file
			)
			ActiveRecord::Base.logger = Logger.new(File.open(db_log_path, 'a'))
		end

		ActiveRecord::Base.connection_pool.with_connection(&db_logic)
	end

	# Return the directory inside user home where this player writes his configurations
	#
	# @return [String] The directory where player writes its configurations
	def user_dir
		@_usr_player_dir ||= File.join(Dir.home, ".cultome")
	end

	# Tries to detect the operating system in which is running.
	#
	# @return [Symbol] the OS detected
	def os
		@_os ||= (
			host_os = RbConfig::CONFIG['host_os']
			case host_os
			when /mswin|msys|mingw|sygwin|bccwin|wince|emc/
				:windows
			when /darwin|mac os/
				:macosx
			when /linux/
				:linux
			when /solaris|bsd/
				:unix
			else
				raise Exception.new("unknown os: #{host_os}")
			end
		)
	end

	# Return the path to the player's config file
	#
	# @return [String] The absoulute path to the config file
	def config_file
		File.join(user_dir, CONFIG_FILE_NAME)
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
		File.join(user_dir, "db_cultome.dat")
	end

	def define_color_palette
		if @color_palette.nil?
			@color_palette = Helper.master_config['core']["color_palette"]
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
				Helper.master_config['core']["color_palette"] = @color_palette
			end
		end

		@color_palette.each_with_index do |color, idx|
			Helper.class_eval do
				define_method "c#{idx+1}".to_sym do |str|
					str.to_s.send(color)
				end
			end
		end
	end

    # Print a message in the screen.
    #
    # @param object [Object] Any object that responds to #to_s.
    # @param continuos [Boolean] If false a new line character is appended at the end of message.
    # @return [String] The message printed.
    def display(object, continuos=false)
        text = object.to_s
        if continuos
            print text
        else
            puts text
        end
        text
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
