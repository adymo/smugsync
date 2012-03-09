
module Smug

class StatusCommand < Command

    include Utils

    def exec
        authenticate
        @albums = JSON::parse Config::config_file("cache", "r").read

        # TODO: support categories and nested categories
        # for now comparison supports only flat list of albums
        current_dir = Config::relative_to_root(Dir.pwd).to_s
        if current_dir == '.'
            compare_albums
        else
            compare_album(current_dir)
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
                puts sprintf("%20s\t%s/(%s files)", "not downloaded", album["Title"], album["Images"].length)
            end
        end

        (local_albums - local_albums_uploaded).each do |local_album|
            puts sprintf("%20s\t%s/(%s files)", "not uploaded", local_album, Pathname.new(local_album).children(false).length)
        end
    end

    # returns true if album is the same locally and remotely
    def compare_album(album)
        # TODO: implement me
    end

end

end
