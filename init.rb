require File.dirname(__FILE__) + '/lib/heroku/commands/rds'

Heroku::Command::Help.group('RDS Tools') do |group|
  group.command 'rds', 'launch a MySQL console for your RDS server'
  group.command 'rds:dump [-f/--force] [<FILE>]', 'download a database dump (default: pp-date.sql.bz2)'
  group.command 'rds:ingress [<SECURITY_GROUP>]', 'authorize your IP ingress access (default: \'default\')'
  group.command 'rds:revoke [<SECURITY_GROUP>]', 'remove previously-granted ingress access (default: \'default\')'
  group.command 'rds:install_tools', 'interactively install the RDS command line tools'
end
