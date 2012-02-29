require 'rake'
require 'rake/testtask'
require 'bundler'

Bundler::GemHelper.install_tasks

desc 'Test'
Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.libs << 'test'
    t.pattern = 'test/*.rb'
    t.verbose = true
end
