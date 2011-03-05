**This is not ready to use yet.**

## Installation

    heroku plugins:install http://github.com/wegowise/heroku-rds.git

## Usage

For now, documentation is limited to `heroku help`:

    === RDS Tools

    rds                                        # launch a MySQL console for your RDS server
    rds:dump [-f/--force] [<FILE>]             # download a database dump (default: app-date.sql.bz2)
    rds:ingress [<SECURITY_GROUP>]             # authorize your IP ingress access (default: 'default')
    rds:revoke [<SECURITY_GROUP>]              # remove previously-granted ingress access (default: 'default')
    rds:install_tools                          # interactively install the RDS command line tools
