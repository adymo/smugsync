
module Smug

class StatusCommand < Command

    include Utils

    ALBUM_STATUS_FORMAT = "%20s\t%s/(%s files)"
    IMAGE_STATUS_FORMAT = "%20s\t%s/%s"

    def exec
        authenticate

        # TODO: support categories and nested categories
        # for now comparison supports only flat list of albums
        status = current_dir_status
        status.each do |album_status|
            if album_status[:status] != :not_modified
                puts sprintf(ALBUM_STATUS_FORMAT, album_status[:status], album_status[:album], album_status[:images].length)
            else
                album_status[:images].each do |image_status|
                    puts sprintf(IMAGE_STATUS_FORMAT, image_status[:status], album_status[:album], image_status[:image])
                end
            end
        end
    end

    def current_dir_status
        current_dir = Config::relative_to_root(Dir.pwd).to_s
        if current_dir == '.'
            albums_status
        else
            Dir::chdir('..')
            status = [album_status(
                :local => current_dir,
                :remote => albums.find { |a| a["Title"] == current_dir }
            )]
            Dir::chdir(current_dir)
            status
        end
    end

    def albums_status
        status = []

        local_albums = Pathname::pwd.children(false).find_all { |a| a.directory? and a.basename.to_s != ".smug" }.map { |a| a.basename.to_s }
        remote_albums = albums.map { |a| a["Title"] }

        status += albums.map do |album|
            album_status(
                :remote => album,
                :local => local_albums.find { |a| a == album["Title"] }
            )
        end
        status += (local_albums - remote_albums).map do |local_album|
            album_status(:remote => nil, :local => local_album)
        end

        status
    end

    def album_status(options = { :local => nil, :remote => nil })
        local = options[:local]
        remote = options[:remote]

        if !local and !remote
            raise "album_status: requires either local or remote album"
        elsif local and !remote
            {
                :album => local,
                :status => :not_uploaded,
                :images => local_images(local).map { |img| { :image => img, :status => :not_uploaded} }
            }
        elsif !local and remote
            {
                :album => remote["Title"],
                :status => :not_downloaded,
                :images => remote_images(remote).map { |img| { :image => img, :status => :not_downloaded} }
            }
        else
            # TODO: assure that local and remote titles are the same
            # TODO: document case insensitivity
            not_uploaded = local_images(local) - remote_images(remote)
            not_downloaded = remote_images(remote) - local_images(local)

            {
                :album => remote["Title"],
                :status => :not_modified,
                :images => not_uploaded.map { |img| { :image => img, :status => :not_uploaded} } + not_downloaded.map { |img| { :image => img, :status => :not_downloaded} }
            }
        end
    end

private

    def albums
        # TODO: status doesn't work without cache
        @albums ||= JSON::parse Config::config_file("cache", "r").read
    end

    def local_images(album_path)
        Pathname.new(album_path).children(false).map do |p|
            p.basename.to_s.downcase.gsub(/^\d\d\d\./, '')
        end
    end

    def remote_images(album)
        album["Images"].map {|p| p["FileName"].downcase }
    end

end

end
