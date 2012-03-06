require 'system_timer'
require 'md5'

module Smug

class UploadCommand < Command

    def exec
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

        authenticate

        existing_files = get("smugmug.images.get", {
            :AlbumID => album_id,
            :AlbumKey => album_key,
            :Heavy => true
        })["Album"]["Images"].map {|p| p["FileName"].downcase }


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

end

