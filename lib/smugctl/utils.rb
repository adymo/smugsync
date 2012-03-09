
module Smug

module Utils

    def status_message(message)
        $stdout.print message
        $stdout.flush
    end

    def method_missing(method, *args, &block)
        # if method looks like smugmug API call, call get()
        if method.to_s =~ /^smugmug_/
            get(method.to_s.gsub('_', '.'), *args, &block)
        else
            super(method, *args, &block)
        end
    end

end

end
