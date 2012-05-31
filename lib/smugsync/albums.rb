
module Smug

class AlbumsCommand < Command

    def exec
        cmd = ARGV[0]
        if cmd == 'list'
            authenticate

            albums = get("smugmug.albums.get")["Albums"]

            format = "%-10s%-10s%-s\n"
            printf(format, "Id", "Key", "Title")
            albums.each do |a|
                printf(format, a["id"], a["Key"], a["Title"])
            end
        else
            $stderr.puts "albums: unknown command #{cmd}"
            exit(1)
        end
    end

end

end
