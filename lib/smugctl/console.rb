require 'trollop'
require 'oauth'
require 'system_timer'
require 'md5'

subcommands = %w( albums upload )

opts = Trollop::options do
    banner <<-END
Usage: smugctl OPTIONS... COMMAND COMMAND_OPTIONS
Controls and synchronizes SmugMug photos and videos.

Examples:
smugctl albums list
smugctl upload ALBUM_ID ALBUM_KEY FILES...

Options:
    END
    opt :verbose,
        "Explain what is being done",
        :short => :v
    stop_on subcommands
end

command = nil
cmd_arg = ARGV.shift
cmd_opts = case cmd_arg
    when "albums"
        command = :albums
    when "upload"
        command = :upload
    when nil
        Trollop::die "command required: #{subcommands.join(', ')}"
    else
        Trollop::die "unknown command #{cmd_arg}"
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
        $stderr.puts "unknown command #{cmd}"
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
            SystemTimer.timeout_after(300) do
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


# Script body itself

config = if File.exists?(CONFIG_FILE)
    JSON.parse(File.read(CONFIG_FILE), :symbolize_names => true) 
else
    {}
end

consumer = OAuth::Consumer.new API_KEY, API_SECRET, {
    :site => "https://secure.smugmug.com",
    :request_token_path => "/services/oauth/getRequestToken.mg",
    :access_token_path => "/services/oauth/getAccessToken.mg",
    :authorize_path => "/services/oauth/authorize.mg"
}

unless config[:access_token]
    # need to request access token from the user
    request_token = consumer.get_request_token
    puts "Authorize app at #{request_token.authorize_url}&Access=Full&Permissions=Modify\nPress Enter when finished"
    gets
    access_token = request_token.get_access_token

    config[:access_token] = {
        :secret => access_token.secret,
        :token => access_token.token
    }
    File.open(CONFIG_FILE, "w+") do |f|
        f.puts config.to_json
    end
end

access_token = OAuth::AccessToken.new(consumer)
access_token.secret = config[:access_token][:secret]
access_token.token = config[:access_token][:token]


send("#{command}_command", access_token)
