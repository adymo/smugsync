require 'trollop'
require 'oauth'
require 'system_timer'
require 'md5'
require 'fileutils'

commands = [
    ["init", "Initialize current folder as SmugMug folder and authorize with SmugMug"],
    ["albums", "List SmugMug albums on the server"],
    ["upload", "Upload files to SmugMug"]
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

# Commands
def albums_command(access_token)
    cmd = ARGV[0]
    if cmd == 'list'
        albums = Album.send(cmd, access_token)

        format = "%-10s%-10s%-s\n"
        printf(format, "Id", "Key", "Title")
        albums.each do |a|
            printf(format, a["id"], a["Key"], a["Title"])
        end
    else
        $stderr.puts "albums: unknown command #{cmd}"
        exit(1)
    end
end

def upload_command(access_token)
    album_id = ARGV[0]
    unless album_id
        $stderr.puts "missing album id"
        exit(1)
    end
    album_key = ARGV[1]
    unless album_key
        $stderr.puts "missing album key"
        exit(1)
    end
    files_to_upload = ARGV[2, ARGV.length]
    if files_to_upload.empty?
        $stderr.puts "specify files to upload"
        exit(1)
    end

    existing_files = Album.list_files(album_id, album_key, access_token)

    num_files = files_to_upload.length
    files_to_upload.each_with_index do |filename, i|
        if existing_files.include? filename.downcase
            puts "Skipping #{filename}: already exists"
            next
        end

        begin
            SystemTimer.timeout_after(1800) do
                puts "Uploading #{filename} (#{Time.now.to_s}) (#{i}/#{num_files})"

                data = File.open(filename, "rb") { |f| f.read }

                req = {}
                req['Content-Length'] = File.size(filename).to_s
                req['Content-MD5'] = MD5.hexdigest(data)
                req['X-Smug-AlbumID'] = album_id
                req['X-Smug-Version'] = '1.3.0'
                req['X-Smug-FileName'] = filename
                req['X-Smug-ResponseType'] = "JSON"

                response = access_token.put("http://upload.smugmug.com/#{filename}", data, req)
                puts " => #{JSON.parse(response.body)["stat"]} (#{Time.now.to_s})"
            end
        rescue Timeout::Error
            puts " => timed out"

            # TODO: delete image from server
        rescue Exception => e
            puts " => error #{e.message}"
            puts e.backtrace.join("\n")

            # TODO: delete image from server
        end
    end
end

def find_config_dir
    # search current dir and upwards until we find .smug dir
    config_dir = nil
    dir = '.'
    while File.expand_path(dir) != '/' do
        config_dir_candidate = File.join(File.expand_path(dir), '.smug')
        if File.exists?(config_dir_candidate)
            config_dir = config_dir_candidate
            break
        end
        dir = File.join(dir, '..')
    end
    config_dir
end

def create_config_dir
    # create .smug in the current directory
    config_dir = File.join(Dir.pwd, '.smug')
    FileUtils.mkdir_p(config_dir)
end

def config_file_name(basename)
    unless config_dir = find_config_dir
        $stderr.puts <<-EOS
Fatal: Not a SmugMug folder (or any parent up to root).
Run 'smug init' to initialize current folder as SmugMug folder.
        EOS
        exit(-1)
    end
    File.join(File.expand_path(config_dir), basename)
end

def oauth_consumer
    consumer = OAuth::Consumer.new API_KEY, API_SECRET, {
        :site => "https://secure.smugmug.com",
        :request_token_path => "/services/oauth/getRequestToken.mg",
        :access_token_path => "/services/oauth/getAccessToken.mg",
        :authorize_path => "/services/oauth/authorize.mg"
    }
end

def authorize
    consumer = oauth_consumer
    # need to request access token from the user
    request_token = consumer.get_request_token
    puts <<-EOS
Authorize app at:
#{request_token.authorize_url}&Access=Full&Permissions=Modify
Press Enter when finished
    EOS
    gets
    access_token = nil
    begin
        access_token = request_token.get_access_token
    rescue OAuth::Unauthorized
        $stderr.puts "Fatal: Could not authorize with SmugMug. Run 'smug init' again."
        exit(-1)
    end

    config = {
        :access_token => {
            :secret => access_token.secret,
            :token => access_token.token
        }
    }
    create_config_dir
    File.open(config_file_name(ACCESS_TOKEN_CONFIG_FILE), "w+") do |f|
        f.puts JSON.pretty_generate(config)
    end
    puts "Initialized SmugMug folder and authorized with SmugMug"
end

def authenticate
    config = JSON.parse(File.read(config_file_name(ACCESS_TOKEN_CONFIG_FILE)), :symbolize_names => true)

    consumer = oauth_consumer

    access_token = OAuth::AccessToken.new(consumer)
    access_token.secret = config[:access_token][:secret]
    access_token.token = config[:access_token][:token]
    access_token
end

def execute_command(command)
    if command == :init
        authorize
        return
    end
    access_token = authenticate
    send("#{command}_command", access_token)
end


# Script body
execute_command(command)
