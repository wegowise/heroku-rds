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

Commands involving data transfer support a progress bar using `pv`.
Install `pv` to see the awesome. Most package managers have a pv
package:

    brew install pv      # OS X
    apt-get install pv   # linux/fink
    port install pv      # BSD/macports

## Usage

Before using any of the tools which connect to the remote database
(`rds`, `rds:dump`, and `rds:pull`) you will need to grant your IP
ingress access by running `rds:ingress`. Once you are finished, you may
optionally use `rds:revoke` to revoke access from your IP.

Command summary:

    rds                                      # launch a MySQL console for your RDS server
    rds:dump [-f/--force] [<FILE>]           # download a database dump (default: app-date.sql.bz2)
    rds:pull [<RAILS_ENV or DATABASE_URL>]   # download the remote database into a local database (default: development)
    rds:ingress [<SECURITY_GROUP>] [<IP>]    # authorize ingress access (defaults: 'default', current IP)
    rds:revoke [<SECURITY_GROUP>] [<IP>]     # remove previously-granted ingress access (defaults: 'default', current IP)
    rds:access                               # show current access settings
    rds:install_tools                        # interactively install the RDS command line tools

You can access this list at any time by typing `heroku help rds` and
detailed help using `heroku help <COMMAND>`.

## Planned features

### Short term

* rds:import - load a local database dump into the remote database
* rds:push - export a local database into the remote database

### Lower priority

* rds:snapshot - capture a snapshot
* rds:restore - restore from a snapshot
* rds:reboot - reboot instance
* rds:describe - show all RDS instances you have access to
* rds:scale - change instance size

These commands are not ingress related so the target of the command
cannot be inferred from DATABASE\_URL. This functionality is also
readily available from the RDS dashboard, so implementing them is not a
priority at this time.
