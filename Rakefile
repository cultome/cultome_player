require "bundler/gem_tasks"

$LOAD_PATH.unshift(File.join(File.dirname(File.expand_path(__FILE__)), 'lib'))

dirname = File.join(File.dirname(File.expand_path(__FILE__)), "tasks")
Dir.entries(dirname).each do |task|
  import "#{dirname}/#{task}" if task.end_with?(".rake")
end
