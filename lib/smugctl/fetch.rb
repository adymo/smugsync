
module Smug

# TODO: maybe rename
class FetchCommand < Command

    def exec
        optparser = Trollop::Parser.new do
            banner <<-END
Usage: smug fetch [<options>]
Show the status of local SmugMug folder.

Options:
            END
            opt :force,
                "Force full refresh of albums and images list",
                :short => :f
        end

        opts = Trollop::with_standard_exception_handling(optparser) do
            optparser.parse(ARGV)
        end

        authenticate

        status_message "Refreshing albums cache"
        refresh_cache(:all_albums, opts) { |album, cache_status| status_message "." }
        status_message " done\n"
    end

    # block is executed for each album with two argumens: album and cache_status
    # cache_status is:
    # - :refreshed      album cache was refreshed
    # - :fresh          album in cache is the same as in server
    # options can be:
    # - :force => true  list of album's images is always refreshed
    #   this is necessary for refreshing cache after uploads and here's why:
    #   - smugmug stores LastUpdated data for albums with 1 second precision
    #   - upload can be fast enough to create album and add image to the album
    #     in one second
    def refresh_cache(albums_to_refresh, options = {}, &block)
        authenticate

        old_cache = if File.exist?(Config::config_file_name("cache"))
            JSON::parse(Config::config_file("cache", "r").read)
        else
            []
        end

        # - to refresh all albums we need to reconstruct the cache from scratch
        #   to make sure that deleted albums are not left in the cache
        # - to refresh selected albums we start from existing cache
        #   and replace only refreshed albums in that cache
        albums_on_server = smugmug_albums_get(:Heavy => true)["Albums"]
        if albums_to_refresh == :all_albums
            albums_to_refresh = albums_on_server
            new_cache = []
        else
            albums_to_refresh_ids = albums_to_refresh.map { |a| a["id"] }
            # refetch albums metadata
            albums_to_refresh = albums_on_server.select { |a| albums_to_refresh_ids.include?(a["id"]) }
            # leave albums that should not be refreshed in the cache
            new_cache = old_cache.reject { |a| albums_to_refresh_ids.include?(a["id"]) }
        end

        albums_to_refresh.each do |album|
            cached_album = old_cache.find { |a| a["id"] == album["id"] }

            if !options[:force] and cached_album and cached_album["LastUpdated"] == album["LastUpdated"]
                # album is in cache and is not changed: copy images from old cache
                # because it can take a long time to get the list of images
                # from server for large albums
                album["Images"] = cached_album["Images"]
                yield(album, :skipped) if block_given?
            else
                # album was changed, get the list of images
                album["Images"] = smugmug_images_get(
                    :AlbumID => album["id"],
                    :AlbumKey => album["Key"],
                    :Heavy => true
                )["Album"]["Images"]
                yield(album, :refreshed) if block_given?
            end

            new_cache << album
        end

        cache_file = Config::config_file("cache", "w+")
        cache_file.puts JSON::pretty_generate(new_cache)
        cache_file.close
    end

end

end
