
module Smug

class FetchCommand < Command

    def exec
        authenticate

        status_message "Refreshing albums cache"
        albums = smugmug_albums_get["Albums"]
        status_message "."
        albums.each do |album|
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
