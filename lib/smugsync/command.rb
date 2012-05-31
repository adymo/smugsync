require 'oauth'
require 'uri'

module Smug

# Base class for all commands
class Command

    include Utils

    # Executes default subcommand, by default 'help'
    # Reimplement in subclasses
    def exec
        help
    end

protected

    attr_accessor :access_token

    # Reimplement in subclasses to print command help
    def help
    end

    def get(method, params = {})
        request_params = params.dup
        request_params["method"] = method
        response = access_token.request(:get,
            URI.escape(Smug::Config::SMUGMUG_REQUEST_URL + "?" +
                request_params.map { |key, value| "#{key}=#{value}" }.join("&"))
        )
        JSON.parse(response.body)
    end

    def put(url, data, headers)
        response = access_token.put(URI.escape(url), data, headers)
        begin
            JSON.parse(response.body)
        rescue Exception => e
            puts "put: invalid JSON response:\n#{response.body}"
            raise e
        end
    end

private

    def authenticate
        config = JSON.parse(File.read(Smug::Config::config_file_name(Smug::Config::ACCESS_TOKEN_CONFIG_FILE)), :symbolize_names => true)

        @access_token = OAuth::AccessToken.new(oauth_consumer)
        @access_token.secret = config[:access_token][:secret]
        @access_token.token = config[:access_token][:token]
    end

    def oauth_consumer
        @oauth_consumer ||= OAuth::Consumer.new Smug::Config::API_KEY,
            Smug::Config::API_SECRET, {
                :site => Smug::Config::SMUGMUG_REQUEST_HOST,
                :request_token_path => "/services/oauth/getRequestToken.mg",
                :access_token_path => "/services/oauth/getAccessToken.mg",
                :authorize_path => "/services/oauth/authorize.mg"
        }
    end

end

end
