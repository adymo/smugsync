require 'fileutils'

module Smug

class DownloadCommand < Command

    def exec
        authenticate

        # TODO: proper argument handling
        albums_to_download = *ARGV

        FetchCommand.new.refresh_cache(:all_albums)
        status = StatusCommand.new.current_dir_status
        Dir::chdir(Config::root_dir)

        status.each_with_index do |album_status, i|
            next if albums_to_download and !albums_to_download.include?(album_status[:album])

            if album_status[:status] == :not_downloaded
                # create album dir
                FileUtils::mkdir(album_status[:album])
            elsif album_status[:status] == :not_uploaded
                next
            end

            # FIXME: this is suboptimal, status should return album, not just its title
            album = albums.find { |a| a["Title"] == album_status[:album] }
            files_to_download = album_status[:images].find_all do |i|
                i[:status] == :not_downloaded
            end.map do |i|
                album["Images"].find { |img| i[:image].downcase == img["FileName"].downcase }
            end
            num_files = files_to_download.length

            files_to_download.each_with_index do |image, i|
                puts "Downloading #{image["FileName"]} (#{i}/#{num_files})"

                if image["Album"]
                    # this is a link to existing image from other album
                    # in SmugMug those are created when you collect images
                    # or create smart albums
                   source_album = albums.find { |a| a["id"] == image["Album"]["id"] }
                   source_image = source_album["Images"].find { |img| img["id"] == image["id"] }
                   source_filename = source_album["Title"] + "/" + source_image["FileName"]
                   target_filename = album["Title"] + "/" + image["FileName"]

                   puts "   ln #{target_filename} #{source_filename}"
                   FileUtils::ln(source_filename, target_filename)
                else
                    # TODO: actually download
                end
            end

        end

    end

private

    def albums
        # TODO: download doesn't work without cache
        @albums ||= JSON::parse Config::config_file("cache", "r").read
    end

end

end
