require 'rake'
require 'fileutils'

def gemspec
  @gemspec ||= eval(File.read('heroku-rds.gemspec'), binding, 'heroku-rds.gemspec')
end

desc "Build the gem"
task :gem => :gemspec do
  sh "gem build heroku-rds.gemspec"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", 'pkg'
end

desc "Install the gem locally"
task :install => :gem do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "Generate the gemspec"
task :generate do
  puts gemspec.to_ruby
end

desc "Validate the gemspec"
task :gemspec do
  gemspec.validate
end

desc 'Run tests'
task :test do |t|
  print 'Testing... '
  sleep(rand(2) + 1)
  puts 'HUGE SUCCESS!'
end

task :default => :test
