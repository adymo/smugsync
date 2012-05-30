
class SmugServer
end

class Smug::Command

    alias_method :get_without_mock, :get
    def get(method, params = {})
        if method == "smugmug.albums.get"
            SmugTestCase.server_dir
            {
                "Albums" => [
                ]
            }
        else
            get_without_mock(method, params)
        end
    end

end
