if RUBY_VERSION < "1.9.0"
    require 'system_timer'
end
require 'digest/md5'
require 'set'

module Smug

class UploadCommand < Command

    # current upload algorithm:
    # 1. get the list not uploaded stuff starting from current dir and below
    # 2. chdir to root (for simplicity)
    # 3. for each album
    #   3.1. create it if it doesn't exist
    #   3.2. upload files
    def exec
        optparser = Trollop::Parser.new do
            banner <<-END
Usage: smug upload [<options>]
Upload files to SmugMug.

Options:
            END
            opt :timeout,
                "Timeout to upload one file in seconds",
                :short => :t,
                :default => 24*3600
        end

        opts = Trollop::with_standard_exception_handling(optparser) do
            optparser.parse(ARGV)
        end

        authenticate

        status = StatusCommand.new.current_dir_status
        Dir::chdir(Config::root_dir)

        modified_albums = Set.new

        status.each_with_index do |album_status, i|
            if album_status[:status] == :not_uploaded
                # create album
                puts "Creating album #{album_status[:album]}"
                result = smugmug_albums_create(
                    "Title" => album_status[:album]
                )
                raise "Cannot create album" unless result["stat"] == "ok"

                # refresh cache for the newly created album
                album = smugmug_albums_getInfo(
                    :AlbumID => result["Album"]["id"],
                    :AlbumKey => result["Album"]["Key"]
                )["Album"]

                FetchCommand.new.refresh_cache([album])
                @albums = nil # TODO: hack to force reparsing of cache file
            elsif album_status[:status] == :not_downloaded
                next
            end

            album = albums.find { |a| a["Title"] == album_status[:album] }

            files_to_upload = album_status[:images].find_all { |i| i[:status] == :not_uploaded }.map { |i| "#{album["Title"]}/#{i[:image]}" }

            File.open("upload.log", "w+") { |f| f.puts "start" }
            num_files = files_to_upload.length
            files_to_upload.each_with_index do |filename, i|
                modified_albums << album

                begin
                    with_timeout(opts[:timeout]) do
                        puts "Uploading #{filename} (#{Time.now.to_s}) (#{i}/#{num_files})"

                        data = File.open(filename, "rb") { |f| f.read }

                        req = {}
                        req['Content-Length'] = File.size(filename).to_s
                        req['Content-MD5'] = Digest::MD5.hexdigest(data)
                        req['X-Smug-AlbumID'] = album["id"].to_s
                        req['X-Smug-Version'] = '1.3.0'
                        req['X-Smug-FileName'] = filename
                        req['X-Smug-ResponseType'] = "JSON"

                        results = put("http://upload.smugmug.com/#{filename}", data, req)
                        puts " => #{results["stat"]} (#{Time.now.to_s})"
                    end
                rescue Timeout::Error
                    puts " => timed out"
                    File.open("upload.log", "a") { |f| f.puts filename }

                    # TODO: delete image from server
                rescue Exception => e
                    puts " => error #{e.message}"
                    puts e.backtrace.join("\n")
                    File.open("upload.log", "a") { |f| f.puts filename }

                    # TODO: delete image from server
                end
            end
        end

        # refresh cache for modified albums only
        puts "Refreshing albums cache"
        FetchCommand.new.refresh_cache(modified_albums, :force => true)
    end

private

    def with_timeout(upload_timeout, &block)
        if RUBY_VERSION < "1.9.0"
            # older ruby need to use SystemTimer because ruby green thread timeout
            # won't terminate threads that execute system calls
            SystemTimer.timeout_after(upload_timeout) do
                yield
            end
        else
            timeout(upload_timeout) do
                yield
            end
        end
    end

    def albums
        # TODO: upload doesn't work without cache
        @albums ||= JSON::parse Config::config_file("cache", "r").read
    end

end

end

