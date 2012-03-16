require 'rubygems'

SPEC = Gem::Specification.new do |s|
    s.name      = "smugctl"
    s.version   = "0.1"
    s.author    = "Alexander Dymo"
    s.email     = "adymo@kdevelop.org"
    s.homepage  = "http://github.com/adymo/smugctl"
    s.platform  = Gem::Platform::RUBY
    s.summary   = "."

    s.add_development_dependency('bundler',     '>= 1.0.0')
    s.add_development_dependency('assert_same', '>= 0.1.0')

    s.add_dependency('trollop',         '>= 1.16.0')
    s.add_dependency('json',            '>= 1.6.0')
    s.add_dependency('oauth',           '>= 0.4.0')
    s.add_dependency('system_timer',    '>= 1.2.0')

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- test/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

    s.require_path      = "lib"
    s.autorequire       = "smugctl"
    s.has_rdoc          = false
end
