#https://www.devdungeon.com/content/enhanced-shell-scripting-ruby
require "io/console"
require "logger"

`touch test.txt`

#puts $?.inpect

#if $?.success?
#  puts "Error happened!"
#end


ARGV.each { |arg|
  puts arg
}

puts ARGV


# # The prompt is optional
# password = IO::console.getpass "Enter Password: "
# puts "Your password was #{password.length} characters long."


# open("test.txt", "w") { |output_file|
#     output_file.print "Write to it just like STDOUT or STDERR"
#     output_file.puts "print(), puts(), and write() all work."
# }
#

logger = Logger.new(STDOUT)
logger.info "user ... did something interesting!"
