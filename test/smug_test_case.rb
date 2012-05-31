require 'test/unit'
require 'rubygems'
require 'smugsync'
require 'assert_same'

# mocks
require 'mock/smug_server'
require 'mock/command'
require 'mock/oauth/tokens/request_token'

class SmugTestCase < Test::Unit::TestCase

    include Smug

    @@server_dir = File.expand_path(File.join(File.dirname(__FILE__), "server"))
    @@local_dir = File.expand_path(File.join(File.dirname(__FILE__), "local"))

    def self.server_dir
        @@server_dir
    end

    def default_test
    end

    def execute(command)
        @command_output = nil
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

    def prepare_server_dir(structure)
        FileUtils::rm_rf(Dir.glob(@@server_dir + "/**"))
        prepare_dir(@@server_dir, structure)
    end

    def prepare_local_dir(structure)
        FileUtils::rm_rf(Dir.glob(@@local_dir + "/**"))
        FileUtils::rm_rf(@@local_dir + "/.smug")

        return if structure == :empty

        FileUtils::mkdir(@@local_dir + "/.smug")
        File.open(@@local_dir + "/.smug/accesstoken", "w+") do |f|
            f.puts JSON.pretty_generate(OAuth::RequestToken::TEST_ACCESS_TOKEN)
        end
        prepare_dir(@@local_dir, structure)
    end

private

    def prepare_dir(dir, structure)
        previous_dir = Dir.pwd
        lines = structure.split("\n")
        indentation = lines.first =~ /^(\s+)/ ? $1.length : 0
        lines.each do |line|
            is_folder = line =~ /^(\s+)/ && $1.length == indentation
            line.strip!
            if is_folder
                FileUtils::cd(dir)
                FileUtils::mkdir(line)
                FileUtils::cd(line)
            else
                # this is a file
                FileUtils::touch(line)
            end
        end
        Dir.chdir(previous_dir)
    end

end
