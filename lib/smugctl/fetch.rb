
module Smug

# TODO: maybe rename
class FetchCommand < Command

    def exec
        authenticate

        cached_albums = JSON::parse Config::config_file("cache", "r").read

        status_message "Refreshing albums cache"
        albums = smugmug_albums_get(:Heavy => true)["Albums"]
        status_message "."

        albums.each do |album|
            # getting the list of images from album is a lengthy operation
            # so skip it if album hasn't changed
            cached_album = cached_albums.find { |a| a["id"] == album["id"] }
            if cached_album and album["LastUpdated"] == album["LastUpdated"]
                status_message "."
                next
            end

            images = smugmug_images_get(:AlbumID => album["id"], :AlbumKey => album["Key"], :Heavy => true)["Album"]["Images"]
            album["Images"] = images
            status_message "."
        end
        cache_file = Config::config_file("cache", "w+")
        cache_file.puts JSON::pretty_generate(albums)
        cache_file.close
        status_message " done\n"
    end

end

end
