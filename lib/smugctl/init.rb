require 'oauth'

module Smug

class InitCommand < Command

    def exec
        # need to request access token from the user
        request_token = oauth_consumer.get_request_token
        puts <<-EOS
Authorize app at:
#{request_token.authorize_url}&Access=Full&Permissions=Modify
Press Enter when finished
        EOS
        gets
        access_token = nil
        begin
            access_token = request_token.get_access_token
        rescue OAuth::Unauthorized
            $stderr.puts "Fatal: Could not authorize with SmugMug. Run 'smug init' again."
            exit(-1)
        end

        config = {
            :access_token => {
                :secret => access_token.secret,
                :token => access_token.token
            }
        }
        Smug::Config::create_config_dir
        File.open(Smug::Config::config_file_name(Smug::Config::ACCESS_TOKEN_CONFIG_FILE), "w+") do |f|
            f.puts JSON.pretty_generate(config)
        end
        puts "Initialized SmugMug folder and authorized with SmugMug"
    end

end

end
