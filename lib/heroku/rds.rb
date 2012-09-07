if Heroku::VERSION < '2.0.0'
  puts "Please upgrade your Heroku gem"
elsif Heroku::VERSION >= '3.0.0'
  puts "Please update your heroku-rds plugin (or find a new maintainer)"
else
  require 'heroku/commands/rds'
end
