require 'rubygems'

SPEC = Gem::Specification.new do |s|
    s.name        = "smugsync"
    s.version     = "0.2"
    s.author      = "Alexander Dymo"
    s.email       = "adymo@kdevelop.org"
    s.homepage    = "http://github.com/adymo/smugsync"
    s.platform    = Gem::Platform::RUBY
    s.summary     = "SmugMug photo and video synchronization tool"
    s.description = "The hacker-friendly command-line tool to synchronize your photos and videos two-way between your computer and SmugMug."

    s.add_development_dependency('assert_same', '>= 0.3.0')

    s.add_dependency('trollop',         '>= 1.16.0')
    s.add_dependency('json',            '>= 1.6.0')
    s.add_dependency('oauth',           '>= 0.4.0')

    if RUBY_VERSION < "1.9.0"
        s.add_dependency('system_timer',    '>= 1.2.0')
    end

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- test/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

    s.require_path      = "lib"
    s.has_rdoc          = false
end
