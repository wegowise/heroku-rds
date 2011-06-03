## Installation

Forewarning: Heroku RDS is not designed to work on Windows.

### Gem-based install (recommended)

Gem-based plugins are new to the Heroku ecosystem, and require first
installing the [Herogems](https://github.com/hone/herogems) plugin:

    heroku plugins:install http://github.com/hone/herogems.git

Now, simply install the gem and enable the plugin:

    gem install heroku-rds
    heroku herogems:enable heroku-rds

You can update to new releases of heroku-rds by running `gem update
heroku-rds`.

### Traditional install

    heroku plugins:install http://github.com/wegowise/heroku-rds.git
    gem install fog

To update, you must re-install the plugin using `heroku
plugins:install`.

### Optional Packages

* Commands involving data transfer support a progress bar using `pv`.
  Install `pv` to see the awesome. Most package managers have a pv
  package:

    brew install pv      # OS X
    apt-get install pv   # linux/fink
    port install pv      # BSD/macports

* `rds:ingress` can use hirb to format tabular data.  `gem install hirb`
  to install it.

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
