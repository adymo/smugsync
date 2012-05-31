
class SmugServer

    attr_reader :server_albums

    def initialize
        @server_albums = get_server_albums_info
    end

    def smugmug_albums_get(params = { :Heavy => false })
        result = {
            "stat" => "ok",
            "method" => "smugmug.albums.get",
            "Albums" => []
        }

        server_albums.each do |album|
            if params[:Heavy]
                result["Albums"] << album.delete_if { |key, value| key == 'Images' }
            else
                result["Albums"] << album.delete_if do |key, value|
                    not ["id", "Key", "Category", "SubCategory", "Title"].include?(key)
                end
            end
        end

        result.to_json
    end

    def smugmug_images_get(params = { :AlbumID => nil, :AlbumKey => nil, :Heavy => false })
        result = {
            "stat" => "ok",
            "method" => "smugmug.images.get",
        }

        album = server_albums.find { |album| album["id"] == params[:AlbumID] and album["Key"] == params[:AlbumKey] }
        return result unless album

        result["Album"] = {
            "id" => params[:AlbumID],
            "Key" => params[:AlbumKey],
            "ImageCount" => 0,
            "Images" => []
        }

        album["Images"].each do |image|
            result["Album"]["ImageCount"] += 1
            if params[:Heavy]
                result["Album"]["Images"] << image
            else
                result["Album"]["Images"] << image.delete_if do |key, value|
                    not ["id", "Key"].include?(key)
                end
            end
        end

        result.to_json
    end

private

    def get_server_albums_info
        albums = []

        server_dir = Dir.new(SmugTestCase.server_dir)
        album_id = 0
        image_id = 0
        server_dir.each do |album_name|
            next if ['.', '..', '.gitignore'].include?(album_name)

            album_full_path = File.join(SmugTestCase.server_dir, album_name)
            raise "Server directory contains file #{album_name} outside of album" unless File.directory?(album_full_path)

            # nice name in smugmug is the name users see in url
            # currently we do nothing with that but let's keep it
            # different from album name
            album_nice_name = album_name.gsub(" ", "_")
            album_id += 1
            album_key = "key#{album_id.to_s(27).tr("0-9a-q", "A-Z")}"

            album = {
                # default settings for smugmug albums that we do not care about
                "WordSearchable" => true,
                "Theme" => {
                    "Name" => "default",
                    "id" => 1
                },
                "SortMethod" => "Position",
                "ImageCount" => 1,
                "Highlight" => {
                    "id" => 1725930094,
                    "Key" => "b9fk6m6",
                    "Type" => "Random"
                },
                "External" => true,
                "Comments" => true,
                "Clean" => false,
                "X3Larges" => true,
                "Keywords" => "",
                "UnsharpAmount" => 0.2,
                "Public" => true,
                "Position" => 1,
                "UnsharpRadius" => 1,
                "SortDirection" => false,
                "Filenames" => true,
                "ColorCorrection" => 2,
                "SquareThumbs" => true,
                "Originals" => true,
                "SmugSearchable" => true,
                "Header" => false,
                "X2Larges" => true,
                "FamilyEdit" => false,
                "EXIF" => true,
                "UnsharpThreshold" => 0.05,
                "Template" => {
                    "id" => 0
                },
                "HideOwner" => false,
                "CanRank" => true,
                "UnsharpSigma" => 1,
                "Share" => true,
                "Protected" => false,
                "Printable" => true,
                "UploadKey" => "",
                "Geography" => true,
                "FriendEdit" => false,
                "Category" => {
                    "Name" => "TestCategory",
                    "id" => 1
                },
                "Passworded" => false,
                "PasswordHint" => "",
                "Password" => "",
                "Description" => "",

                # albums settings that we currently care about
                "id" => album_id,
                "Key" => album_key,
                "NiceName" => album_nice_name,
                "URL" => "http://user.smugmug.com/TestCategory/#{album_nice_name}/#{album_id}_#{album_key}",
                "Title" => album_name,
                "LastUpdated" => "2012-02-26 02:40:44",
                "Images" => []
            }

            album_dir = Dir.new(album_full_path)
            album_dir.each do |image_name|
                next if ['.', '..'].include?(image_name)

                image_id += 1
                image_key = "key#{image_id.to_s(27).tr("0-9a-q", "A-Z")}"

                album["Images"] << {
                    # image urls, for now not used/tested
                    "URL" => "http://url",
                    "OriginalURL" => "http://original_url",
                    "X3LargeURL" => "http://xl3_url",
                    "X2LargeURL" => "http://xl2_url",
                    "XLargeURL" => "http://xl_url",
                    "LargeURL" => "http://large_url",
                    "MediumURL" => "http://medium_url",
                    "SmallURL" => "http://small_url",
                    "TinyURL" => "http://tiny_url",
                    "ThumbURL" => "http://thumb_url",
                    "LightboxURL" => "http://lightbox_url",

                    # settings that we don't care about
                    "Status" => "Open",
                    "Keywords" => "",
                    "Hidden" => false,
                    "Serial" => 1,
                    "Position" => 1,
                    "Size" => 91144,
                    "Width" => 638,
                    "Height" => 638,
                    "Format" => "JPG",
                    "Date" => "2012-02-26 02:40:44",
                    "Watermark" => false,
                    "MD5Sum" => "d63af258e5ec78db084af9164a8f3581",
                    "Caption" => "",
                    "LastUpdated" => "2012-02-26 02:42:01",

                    # albums settings that we currently care about
                    "FileName" => image_name,
                    "id" => image_id,
                    "Key" => image_key,
                    "Type" => "Album",
                }
            end

            albums << album
        end
        albums
    end

end
