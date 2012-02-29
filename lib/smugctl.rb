require 'json'
require 'smugctl/album'
require 'smugctl/upload'

API_KEY = 'TLL8o6xrHJxq6LNBLczKAmDADA5R2v7K'
API_SECRET = '2cf156d1b719da74d3b565b8628d1687'
HTTP_URL = "http://api.smugmug.com/services/api/json/1.3.0/"
HTTPS_URL = "https://secure.smugmug.com/services/api/json/1.3.0/"
CONFIG_FILE = File::expand_path("~/.smugsync")
