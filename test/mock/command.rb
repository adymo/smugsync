
class Smug::Command

    alias_method :get_without_mock, :get
    def get(method, params = {})
        mocked_method = method.gsub(".", "_")
        server = SmugServer.new
        if server.respond_to?(mocked_method)
            JSON.parse(server.send(mocked_method, params))
        else
            get_without_mock(method, params)
        end
    end

end
