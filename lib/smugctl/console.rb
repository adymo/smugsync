require 'trollop'

$KCODE = 'u'

commands = [
    ["init", "Initialize current folder as SmugMug folder and authorize with SmugMug"],
    ["albums", "List SmugMug albums on the server"],
    ["upload", "Upload files to SmugMug"],
    ["fetch", "Fetch the list of albums and images from the server"],
]

optparser = Trollop::Parser.new do
    banner <<-END
Usage: smug [<options>] <command> [<args>]
Manage SmugMug photos and videos.

Available smug commands are:
#{commands.map { |cmd, description| sprintf("   %-11s%s", cmd, description) }.join("\n")}

See 'smug help <command>' for more information on a specific command.

Options:
    END
    opt :verbose,
        "Explain what is being done",
        :short => :v
    stop_on commands
end

command = nil
opts = Trollop::with_standard_exception_handling(optparser) do
    optparser.parse(ARGV)
    cmd_arg = ARGV.shift
    raise Trollop::HelpNeeded if cmd_arg.nil? or cmd_arg.empty?

    if commands.map { |cmd, description| cmd }.include? cmd_arg
        command = cmd_arg.to_sym
    else
        $stderr.puts "smug: '#{cmd_arg}' is not a smug command. See 'smug --help'."
        exit(-1)
    end
end

command = Smug.const_get("#{command.to_s.capitalize}Command").new
command.exec
