require 'heroku/commands/rds'

Heroku::Command::Help.group('RDS Tools') do |group|
  group.command 'rds', 'launch a MySQL console for your RDS server'
  group.command 'rds:dump [-f/--force] [<FILE>]', 'download a database dump (default: app-date.sql.bz2)'
  group.command 'rds:pull [<RAILS_ENV or DATABASE_URL>]', 'download the remote database into a local database (default: development)'
  group.command 'rds:ingress [<SECURITY_GROUP>] [<IP>]', 'grant an IP ingress access (default: \'default\', current IP)'
  group.command 'rds:revoke [<SECURITY_GROUP>] [<IP>]', 'remove previously-granted ingress access (default: \'default\', current IP)'
  group.command 'rds:access', 'show current access settings'
end
