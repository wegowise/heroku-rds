begin
  require 'fog'
rescue LoadError => e
  if e.message =~ /fog/
    puts ' !'
    puts ' ! Fog is required to use heroku-rds.'
    puts ' !'
    puts ' !     http://fog.io'
    puts ' !'
    exit
  end
  raise
end

require 'heroku/rds'
