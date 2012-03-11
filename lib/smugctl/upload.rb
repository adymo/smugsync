require 'system_timer'
require 'md5'

module Smug

class UploadCommand < Command

    # current upload algorithm:
    # 1. get the list not uploaded stuff starting from current dir and below
    # 2. chdir to root (for simplicity)
    # 3. for each album
    #   3.1. create it if it doesn't exist
    #   3.2. upload files
    def exec
        authenticate

        status = StatusCommand.new.current_dir_status
        Dir::chdir(Config::root_dir)

        status.each_with_index do |album_status, i|
            if album_status[:status] == :not_uploaded
                # create album
                result = smugmug_albums_create(
                    "Title" => album_status[:album]
                )
                raise "Cannot create album" unless result["stat"] == "ok"
                # refresh cache
                FetchCommand.new.exec
            elsif album_status[:status] == :not_downloaded
                next
            end

            album = albums.find { |a| a["Title"] == album_status[:album] }

            files_to_upload = album_status[:images].find_all { |i| i[:status] == :not_uploaded }.map { |i| "#{album["Title"]}/#{i[:image]}" }

            num_files = files_to_upload.length
            files_to_upload.each_with_index do |filename, i|
                begin
                    SystemTimer.timeout_after(1800) do
                        puts "Uploading #{filename} (#{Time.now.to_s}) (#{i}/#{num_files})"

                        data = File.open(filename, "rb") { |f| f.read }

                        req = {}
                        req['Content-Length'] = File.size(filename).to_s
                        req['Content-MD5'] = MD5.hexdigest(data)
                        req['X-Smug-AlbumID'] = album["id"].to_s
                        req['X-Smug-Version'] = '1.3.0'
                        req['X-Smug-FileName'] = filename
                        req['X-Smug-ResponseType'] = "JSON"

                        results = put("http://upload.smugmug.com/#{filename}", data, req)
                        puts " => #{results["stat"]} (#{Time.now.to_s})"
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
    end

private

    def albums
        # TODO: upload doesn't work without cache
        @albums ||= JSON::parse Config::config_file("cache", "r").read
    end

end

end

