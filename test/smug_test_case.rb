require 'test/unit'
require 'rubygems'
require 'smugctl'
require 'assert_same'

class SmugTestCase < Test::Unit::TestCase

    include Smug

    @@server_dir = File.expand_path(File.join(File.dirname(__FILE__), "server"))
    @@local_dir = File.expand_path(File.join(File.dirname(__FILE__), "local"))

    def default_test
    end

    def execute(command)
        $stdout = @stdout = StringIO.new
        $stderr = @stderr = StringIO.new

        previous_dir = Dir.pwd
        Dir.chdir(@@local_dir)
        command = Smug.const_get("#{command.to_s.capitalize}Command").new
        begin
            command.exec
        rescue SystemExit
            # do not exit, we'll want to check command output
        end
        @command_output = [@stdout.string, @stderr.string].reject { |out| out.empty? }.join("\n")
        Dir.chdir(previous_dir)

        $stdout = STDOUT
        $stderr = STDERR
    end

    def command_output
        @command_output
    end

end
