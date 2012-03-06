require 'fileutils'

module Smug

module Config

API_KEY = 'TLL8o6xrHJxq6LNBLczKAmDADA5R2v7K'
API_SECRET = '2cf156d1b719da74d3b565b8628d1687'

SMUGMUG_REQUEST_HOST = "https://secure.smugmug.com"
SMUGMUG_REQUEST_URL = "/services/api/json/1.3.0/"

ACCESS_TOKEN_CONFIG_FILE = "accesstoken"

def find_config_dir
    # search current dir and upwards until we find .smug dir
    config_dir = nil
    dir = '.'
    while File.expand_path(dir) != '/' do
        config_dir_candidate = File.join(File.expand_path(dir), '.smug')
        if File.exists?(config_dir_candidate)
            config_dir = config_dir_candidate
            break
        end
        dir = File.join(dir, '..')
    end
    config_dir
end

def create_config_dir
    # create .smug in the current directory
    config_dir = File.join(Dir.pwd, '.smug')
    FileUtils.mkdir_p(config_dir)
end

def config_file_name(basename)
    unless config_dir = find_config_dir
        $stderr.puts <<-EOS
Fatal: Not a SmugMug folder (or any parent up to root).
Run 'smug init' to initialize current folder as SmugMug folder.
        EOS
        exit(-1)
    end
    File.join(File.expand_path(config_dir), basename)
end

module_function :config_file_name, :find_config_dir, :create_config_dir

end

end
