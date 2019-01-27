require 'colorize'

module CultomePlayer::Utils
  def db_file_exists?
    File.exists?(db_file)
  end

  def create_db_file
    Dir.mkdir(base_dir) unless File.exists?(base_dir)
    File.write(db_file, "{}")
  end

  def stdout
    STDOUT
  end

  # Print a string into stdout (not STDOUT) and finish with a newline character.
  #
  # @param msg [String] The value to be printed.
  # @return [String] The value printed.
  def display(msg)
    stdout.puts msg
    return "#{msg}\n"
  end

  def show_error(msg)
    type, message = msg.split(":")
    display c3("[#{type}] #{message}")
  end

  def show_response(r)
    return if r.respond_to?(:no_response)

    if r.respond_to?(:response_type)
      res_obj = r.send(r.response_type)
      if res_obj.respond_to?(:each)
        # es una lista
        display to_display_list(res_obj)
      elsif res_obj.class == String
        # es un mensaje
        display r.success? ? res_obj : c3(res_obj.to_s)
      else
        display c3("(((#{res_obj.to_s})))")
      end

      # Dont has response_type, eg has a message
    elsif r.respond_to?(:message)
      display r.success? ? c15(r.message) : c3(r.message)
    else
      display c3("!!! #{r} !!!")
    end
  end

  # Define the 18 colors allowed in my console scheme
  (1..18).each do |idx|
    define_method "c#{idx}" do |str|
      case idx
      when 1 then str.colorize(:blue)
      when 2 then str.colorize(:black)
      when 3 then str.colorize(:red)
      when 4 then str.colorize(:green)
      when 5 then str.colorize(:yellow)
      when 6 then str.colorize(:blue)
      when 7 then str.colorize(:magenta)
      when 8 then str.colorize(:cyan)
      when 9 then str.colorize(:white)
      when 10 then str.colorize(:default)
      when 11 then str.colorize(:light_black)
      when 12 then str.colorize(:light_red)
      when 13 then str.colorize(:light_green)
      when 14 then str.colorize(:light_yellow)
      when 15 then str.colorize(:light_blue)
      when 16 then str.colorize(:light_magenta)
      when 17 then str.colorize(:light_cyan)
      when 18 then str.colorize(:light_white)
      end
    end
  end
end
