## Installation

### Gem-based install (recommended)

    heroku plugins:install http://github.com/hone/herogems.git
    gem install heroku-rds
    heroku herogems:enable heroku-rds
    heroku rds:install_tools

You can update to new releases of heroku-rds by running `gem update
heroku-rds`.

### Traditional install

    heroku plugins:install http://github.com/wegowise/heroku-rds.git
    heroku rds:install_tools

To update, you must re-install the plugin using `heroku
plugins:install`.

### Optional Packages

Commands involving data transfer support a progress bar using `pv`.
Install `pv` to see the awesome. Most \*nix package managers have a pv
package:

    brew install pv      # OS X
    apt-get install pv   # linux/fink
    port install pv      # BSD/macports

## Usage

Before using any of the tools which connect to the remote database
(`rds`, `rds:dump`, and `rds:pull`) you will need to grant your IP
ingress access by running `rds:ingress`. Once you are finished, you may
wish to `rds:revoke` your IP.

    rds                                        # launch a MySQL console for your RDS server
    rds:dump [-f/--force] [<FILE>]             # download a database dump (default: app-date.sql.bz2)
    rds:pull [<RAILS_ENV or DATABASE_URL>]     # download the remote database into a local database (default: development)
    rds:ingress [<SECURITY_GROUP>]             # authorize your IP ingress access (default: 'default')
    rds:revoke [<SECURITY_GROUP>] [<IP>]       # remove previously-granted ingress access (defaults: 'default', current IP)
    rds:access                                 # show current access settings
    rds:install_tools                          # interactively install the RDS command line tools


## Planned features

### Short term

* rds:import - load a local database dump into the remote database
* rds:push - export a local database into the remote database
* Automatic ingress access and revocation around commands - RDS may be
  too slow to do this in a reasonable way, though.

### Lower priority

* rds:snapshot - capture a snapshot
* rds:restore - restore from a snapshot
* rds:reboot - reboot instance
* rds:describe - show all RDS instances you have access to
* rds:scale - change instance size

These commands are not ingress related so the target of the command
cannot be inferred from DATABASE\_URL. Calling these commands manually
is fairly straightforward using the `heroku-rds` wrapper, so a dedicated
command is a bit overkill, but I think could prove useful.
