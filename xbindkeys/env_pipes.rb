
class EnvPipes

  def self.get_pipes
    gem_env = `gem environment | grep "INSTALLATION DIRECTORY:"`
    if gem_env =~ /: (.+)$/
      gems_dir = File.join($1, "gems")
      cultome_gem = Dir.entries(gems_dir).select{|f| f =~ /^cultome_player/}.sort.pop
      pipes = open(File.join(gems_dir, cultome_gem, "config", "environment.yml"), "r").map{|line| line =~ /command_pipe: (.+)$/; $1.chomp if $1 }.compact
      return pipes.map{|p| File.expand_path(p) }
    end
  end

  def self.send(msg)
    puts "[*] Sending message '#{msg}' to pipes"
    pipes = get_pipes
    puts "[*] Pipes: #{pipes.inspect}"
    pipes.each{|p| write(p, msg) }
  end

  def self.write(pipe, msg)
    begin
    puts "[*] Writing to '#{pipe}'"
      open(pipe, File::WRONLY | File::NONBLOCK | File::SYNC){|out| out.puts msg}
    rescue Errno::ENXIO, Errno::ENOENT => e
      #puts e.message
    end
  end
end
