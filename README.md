## Installation

    heroku plugins:install http://github.com/wegowise/heroku-rds.git

## Usage

For now, documentation is limited to `heroku help`:

    === RDS Tools

    rds                                        # launch a MySQL console for your RDS server
    rds:dump [-f/--force] [<FILE>]             # download a database dump (default: app-date.sql.bz2)
    rds:pull [<RAILS_ENV or DATABASE_URL>]     # download the remote database into a local database (default: development)
    rds:ingress [<SECURITY_GROUP>]             # authorize your IP ingress access (default: 'default')
    rds:revoke [<SECURITY_GROUP>]              # remove previously-granted ingress access (default: 'default')
    rds:install_tools                          # interactively install the RDS command line tools

Commands involving data transfer support a progress bar using `pv`.
Install `pv` to see the awesome.

## Planned features

### Short term

* rds:import - load a local database dump into the remote database
* rds:push - export a local database into the remote database
* Automatic ingress access and revocation around commands - RDS may be
  too slow to do this in a reasonable way, though.

### Lower priority

* rds:access - show current ingress access
* rds:snapshot - capture a snapshot
* rds:restore - restore from a snapshot
* rds:reboot - reboot instance
* rds:describe - show all RDS instances you have access to
* rds:scale - change instance size

These commands are not ingress related so the target of the command
cannot be inferred from DATABASE\_URL. Calling these commands manually
is fairly straightforward using the `heroku-rds` wrapper, so a dedicated
command is a bit overkill, but I think could prove useful.
