require 'smug_test_case'

class StatusCommandTest < SmugTestCase

    def test_empty_local_dir
        execute("status")
        assert_same command_output, <<-END
            Fatal: Not a SmugMug folder (or any parent up to root).
            Run 'smug init' to initialize current folder as SmugMug folder.
        END
    end

end
