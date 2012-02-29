
class Album

    def self.list(access_token)
        response = access_token.request(:get, "/services/api/json/1.3.0/?method=smugmug.albums.get")
        albums = JSON.parse(response.body)["Albums"]
    end

    def self.list_files(album_id, album_key, access_token)
        response = access_token.request(:get, "/services/api/json/1.3.0/?method=smugmug.images.get&AlbumID=#{album_id}&AlbumKey=#{album_key}&Heavy=true")
        JSON.parse(response.body)["Album"]["Images"].map {|p| p["FileName"].downcase }
    end

end
