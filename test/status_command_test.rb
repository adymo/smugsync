require 'smug_test_case'

class StatusCommandTest < SmugTestCase

    def test_empty_local_dir
        prepare_local_dir(:empty)
        execute "status"
        assert_same command_output, <<-END
            Fatal: Not a SmugMug folder (or any parent up to root).
            Run 'smug init' to initialize current folder as SmugMug folder.
        END
    end

    def test_status
        prepare_server_dir <<-END
            Sample Folder 1
                Pic 1.png
                Pic 2.jpg
                Pic 3.jpg
                Pic 4.jpg
                pic 5.jpg
            sample folder 2
                Pic 1.png
                Pic 2.jpg
            sAmple foLder 3
                Pic 1.png
                Pic 2.jpg
        END
        prepare_local_dir <<-END
            Sample Folder 1
                Pic 1.png
                Pic 3.jpg
                pic 4.jpg
                Pic 5.jpg
            sample folder 2
                Pic 1.png
                Pic 2.jpg
            sample folder 4
                Pic 1.png
                Pic 2.jpg
        END
        execute "fetch"
        execute "status"
        assert_same command_output, <<-END
                    not_uploaded	Sample Folder 1/Pic 5.jpg
                    not_uploaded	Sample Folder 1/pic 4.jpg
                  not_downloaded	Sample Folder 1/pic 5.jpg
                  not_downloaded	Sample Folder 1/Pic 2.jpg
                  not_downloaded	Sample Folder 1/Pic 4.jpg
                  not_downloaded	sAmple foLder 3/(2 files)
                    not_uploaded	sample folder 4/(2 files)
        END
    end

end
