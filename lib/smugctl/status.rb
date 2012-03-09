
module Smug

class StatusCommand < Command

    include Utils

    ALBUM_STATUS_FORMAT = "%20s\t%s/(%s files)"
    ALBUM_MODIFIED_STATUS_FORMAT = "%20s\t%s"
    IMAGES_STATUS_FORMAT = "%20s\t%s/(%s files)"
    IMAGE_STATUS_FORMAT = "%20s\t%s/%s"
    FILE_OUTPUT_COUNT_LIMIT = 10

    def exec
        authenticate
        @albums = JSON::parse Config::config_file("cache", "r").read

        # TODO: support categories and nested categories
        # for now comparison supports only flat list of albums
        current_dir = Config::relative_to_root(Dir.pwd).to_s
        if current_dir == '.'
            compare_albums
        else
            Dir::cwd("..")
            compare_album(@albums.find { |a| a["Title"] == current_dir })
            Dir::cwd(current_dir)
        end
    end

private

    def compare_albums
        local_albums = Pathname::pwd.children(false).find_all { |a| a.directory? and a.basename.to_s != ".smug" }.map { |a| a.basename.to_s }
        local_albums_uploaded = []

        @albums.each do |album|
            if local_albums.include? album["Title"]
                local_albums_uploaded << album["Title"]
                compare_album(album)
            else
                puts sprintf(ALBUM_STATUS_FORMAT, "not downloaded", album["Title"], album["Images"].length)
            end
        end

        (local_albums - local_albums_uploaded).each do |local_album|
            puts sprintf(ALBUM_STATUS_FORMAT, "not uploaded", local_album, Pathname.new(local_album).children(false).length)
        end
    end

    def compare_album(album)
        local_images = Pathname.new(album["Title"]).children(false).map { |p| p.basename.to_s.downcase }
        remote_images = album["Images"].map {|p| p["FileName"].downcase }

        not_uploaded = local_images - remote_images
        not_downloaded = remote_images - local_images

        if not_uploaded.length > FILE_OUTPUT_COUNT_LIMIT
                puts sprintf(IMAGES_STATUS_FORMAT, "not uploaded", album["Title"], not_uploaded.length)
        elsif not_uploaded.length > 0
            not_uploaded.each do |p|
                puts sprintf(IMAGE_STATUS_FORMAT, "not uploaded", album["Title"], p)
            end
        end

        if not_downloaded.length > FILE_OUTPUT_COUNT_LIMIT
                puts sprintf(IMAGES_STATUS_FORMAT, "not downloaded", album["Title"], not_downloaded.length)
        elsif not_downloaded.length > 0
            not_downloaded.each do |p|
                puts sprintf(IMAGE_STATUS_FORMAT, "not downloaded", album["Title"], p)
            end
        end
    end

end

end
