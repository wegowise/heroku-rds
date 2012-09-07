# heroku-rds

Forewarning: Heroku RDS is not designed to work on Windows.

## Installation

    gem install fog
    heroku plugins:install https://github.com/wegowise/heroku-rds

Re-install to update.

## Optional Packages

* Commands involving data transfer support a progress bar using [Pipe Viewer](http://www.ivarch.com/programs/pv.shtml).
  Most package managers have a pv package:

```shell
brew install pv      # OS X
apt-get install pv   # linux/fink
port install pv      # BSD/macports</pre>
```

* `rds:access` will use hirb if available to format the results.  `gem
  install hirb` to see it.

## Usage

Access the command list at any time by typing `heroku help rds`:

    Usage: heroku rds

     Opens a MySQL console connected to the current database. Ingress access
     is required to run this command (use rds:ingress to grant access).

    Additional commands, type "heroku help COMMAND" for more details:

      rds:access                            # displays current ingress access settings
      rds:dump [FILE]                       # Download a database dump, bzipped and saved locally
      rds:import FILE                       # uploads a local database dump into the remote databse
      rds:ingress [IP] [SECURITY GROUP]     # Authorize ingress access to a particular IP
      rds:pull [RAILS_ENV or DATABASE_URL]  # downloads the remote database into a local database
      rds:push [RAILS_ENV or DATABASE_URL]  # uploads the local database into the remote database
      rds:revoke [IP] [SECURITY GROUP]      # Revokes previously-granted ingress access from a particular IP

## Planned features

* rds:snapshot - capture a snapshot
* rds:restore - restore from a snapshot
* rds:reboot - reboot instance
* rds:describe - show all RDS instances you have access to
* rds:scale - change instance size

These commands are not ingress related so the target of the command
cannot be inferred from DATABASE\_URL. This functionality is also
readily available from the RDS dashboard, so implementing them is not
considered critical.
