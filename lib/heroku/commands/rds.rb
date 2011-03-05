require 'uri'

module Heroku::Command; class Rds < BaseWithApp

  DOWNLOAD_URL = "http://s3.amazonaws.com/rds-downloads/RDSCli.zip"
  AWS_CERTIFICATES_URL = "https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key"
  attr_accessor :database_uri

  def initialize(*)
    super
    self.database_uri = parse_database_uri
    validate_uri
  end

  def index
    check_dependencies('mysql')
    exec *(['mysql', '--compress'] + mysql_auth_args + [db_name])
  end

  def dump
    check_dependencies('mysqldump', 'bzip2', '/bin/sh')
    options = {}
    while arg = args.shift
      case arg
      when '-f', '--force'
        options[:force] = true
      when /^[^-]/
        raise CommandFailed, "too many arguments passed" if options[:filename]
        options[:filename] = arg
      else
        raise CommandFailed, "unsupported option: #{arg}"
      end
    end

    options[:filename] ||= "#{app}-#{Time.now.stftime('%Y-%m-%d')}.sql.bz2"
    options[:filename] += '.sql.bz2' unless options[:filename] =~ /\.sql(\.bz2)?$/
    options[:filename] += '.bz2' unless options[:filename] =~ /\.bz2$/

    raise CommandFailed, "file already exists. use --force to override." if
      File.exists?(options[:filename]) && !options[:force]

    exec('/bin/sh', '-c',
         "mysqldump --compress --single-transaction '#{mysql_auth_args.join("' '")}' '#{db_name}' " +
         %{| bzip2 > '#{filename}'})
  end

  def install_tools
    check_dependencies('curl', 'unzip')

    display "This should either be in your path, or you will have to add it to your path."
    path = Readline.readline "Install to: [$HOME/bin] "
    path = File.join(ENV['HOME'], 'bin') if path.empty?

    raise CommandFailed, "#{path}/rds-tools already exists. Please remove before installing." if
      File.exists?("#{path}/rds-tools")

    display "-" * 72
    display "You can modify the following settings at any time by editing the script at #{path}/heroku-rds"
    display "-" * 72
    display "On some systems, you may need provide the path to your JRE (JAVA_HOME)"
    display "The script will always use $JAVA_HOME if it is set at runtime."
    java_home = Readline.readline "Set JAVA_HOME: [#{ENV['JAVA_HOME']}] "
    java_home = ENV['JAVA_HOME'].to_s if java_home.empty?

    display
    display "Create and download a X.509 certificate and private key at:"
    display AWS_CERTIFICATES_URL
    display "Make sure to safeguard these files! Set permissions appropriately (chmod 600 *.pem)!"
    display
    private_key = Readline.readline "Full path to your private key: [$HOME/bin/rds-keys/pk.pem] "
    private_key = '$HOME/bin/rds-keys/pk.pem' if private_key.empty?

    certificate = Readline.readline "Full path to your X.509 certificate: [$HOME/bin/rds-keys/cert.pem] "
    certificate = '$HOME/bin/rds-keys/cert.pem' if certificate.empty?

    FileUtils.mkdir_p("#{path}/tmp-rds-tools")
    system("curl -Ss #{DOWNLOAD_URL} > #{path}/tmp-rds-tools/rds-tools.zip")
    system("unzip #{path}/tmp-rds-tools/RDSCli.zip")
    File.unlink("#{path}/tmp-rds-tools/RDSCli.zip")
    unzipped_directory = Dir["#{path}/tmp-rds-tools/*"].first
    File.rename(unzipped_directory, "#{path}/rds-tools")
    Dir.rmdir("#{path}/tmp-rds-tools")
    File.open("#{path}/heroku-rds", 'w') do |f|
      f.puts "#!/bin/sh"
      f.puts %{if [ "$JAVA_HOME" == "" ]; then export JAVA_HOME='#{java_home}'; fi}
      f.puts %{export AWS_RDS_HOME='#{path}/rds-tools'}
      f.puts %{export EC2_CERT='#{certificate}'}
      f.puts %{export EC2_PRIVATE_KEY='#{private_key}'}
      f.puts %{exec "$AWS_RDS_HOME/bin/rds-$1"}
    end
    File.chmod("#{path}/heroku-rds", '0700')

    display "Installation complete! Remember to add #{path} to your path if necessary."
  end

  def ingress
    check_dependencies('heroku-rds')
    security_group = args.shift || 'default'

    exec(%W{rds authorize-db-security-group-ingress #{security_group} -i #{ip}/32})
  end

  def revoke
    check_dependencies('heroku-rds')
    security_group = args.shift || 'default'

    exec(%W{rds revoke-db-security-group-ingress #{security_group} -i #{ip}/32})
  end

  private

  def ip
    # simple rack app which returns your external IP
    RestClient::Resource.new("http://ip4.heroku.com")['/'].get.strip
  end

  def parse_database_uri
    URI.parse(heroku.config_vars(app)['DATABASE_URL'])
  end

  def db_name
    database_uri.path.sub('/', '')
  end

  def mysql_auth_args
    ['-u', database_uri.user, '-p' + database_uri.pass, '-h', database_uri.host]
  end

  def exec(*args)
    ENV['DEBUG'] ? puts("exec(): #{args.inspect}") && exit : super
  end

  def system(*args)
    exec = ENV['DEBUG'].nil?
    unless exec
      puts("system(): #{args.inspect}")
      exec = Readline.readline("execute? [yN] ") == 'y'
    end
    if exec
      super or raise CommandFailed, "command failed [code=#{$?.exitstatus}]: " + system.join(' ')
    end
  end

  def validate_uri
    raise CommandFailed, 'You are not using a MySQL server.' unless database_uri.scheme =~ /^mysql/
  end

  def check_dependencies(*commands)
    commands.each do |cmd|
      path = `which #{cmd}`.strip
      raise CommandFailed, "#{cmd}: not found in path" if path.empty?
      raise CommandFailed, "#{cmd}: not executable" unless File.executable?(path)
    end
  end

end; end