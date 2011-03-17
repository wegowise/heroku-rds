require 'uri'

module Heroku::Command; class Rds < BaseWithApp

  DOWNLOAD_URL = "http://s3.amazonaws.com/rds-downloads/RDSCli.zip"
  AWS_CERTIFICATES_URL = "https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key"
  attr_accessor :database_uri

  def initialize(*)
    super
    self.database_uri = parse_database_uri
    validate_db(database_uri)
  end

  def index
    check_dependencies('mysql')
    exec *(['mysql', '--compress'] + mysql_args(database_uri))
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

    options[:filename] ||= "#{app}-#{Time.now.strftime('%Y-%m-%d')}.sql.bz2"
    options[:filename] += '.sql.bz2' unless options[:filename] =~ /\.sql(\.bz2)?$/
    options[:filename] += '.bz2' unless options[:filename] =~ /\.bz2$/

    raise CommandFailed, "file already exists. use --force to override." if
      File.exists?(options[:filename]) && !options[:force]

    exec('/bin/sh', '-c',
         "mysqldump --compress --single-transaction #{args_to_s(mysql_args(database_uri))}" +
         (pv_installed? ? '| pv ' : '') +
         %{| bzip2 > '#{options[:filename]}'})
  end

  def install_tools
    check_dependencies('curl', 'unzip', 'java', '/bin/bash')

    display "This should either be in your path, or you will have to add it to your path."
    path = ask "Path to install [#{ENV['HOME']}/bin]: "
    path = File.join(ENV['HOME'], 'bin') if path.empty?

    raise CommandFailed, "#{path}/rds-tools already exists. Please remove before installing." if
      File.exists?("#{path}/rds-tools")

    display "-" * 72
    display "You can modify the following settings at any time by editing the script"
    display "at #{path}/heroku-rds"
    display "-" * 72
    display "On most systems, you will need provide the path to your JRE (JAVA_HOME)."
    display "The default setting should work on OS X."
    display "The script will always use $JAVA_HOME if it is set at runtime."
    default_java_home = ENV['JAVA_HOME'] || '/System/Library/Frameworks/JavaVM.framework/Home'
    java_home = ask "Set JAVA_HOME [#{default_java_home}]: "
    java_home = default_java_home if java_home.empty?

    display "\nCreate and download a X.509 certificate and private key at:"
    display AWS_CERTIFICATES_URL
    display "Make sure to safeguard these files! Set permissions appropriately (chmod 600 *.pem)!"
    private_key = ask "\nFull path to your private key [$HOME/bin/rds-keys/pk.pem]: "
    private_key = '$HOME/bin/rds-keys/pk.pem' if private_key.empty?

    certificate = ask "\nFull path to your X.509 certificate [$HOME/bin/rds-keys/cert.pem]: "
    certificate = '$HOME/bin/rds-keys/cert.pem' if certificate.empty?

    FileUtils.mkdir_p("#{path}/tmp-rds-tools")
    system("curl -Ss #{DOWNLOAD_URL} > #{path}/tmp-rds-tools/rds-tools.zip")
    system("unzip -qq #{path}/tmp-rds-tools/rds-tools.zip -d #{path}/tmp-rds-tools")
    File.unlink("#{path}/tmp-rds-tools/rds-tools.zip")
    unzipped_directory = Dir["#{path}/tmp-rds-tools/*"].first
    File.rename(unzipped_directory, "#{path}/rds-tools")
    Dir.rmdir("#{path}/tmp-rds-tools")
    File.open("#{path}/heroku-rds", 'w') do |f|
      f.puts "#!/bin/bash"
      f.puts %{if [ "$JAVA_HOME" = "" ]; then export JAVA_HOME='#{java_home}'; fi}
      f.puts %{export AWS_RDS_HOME='#{path}/rds-tools'}
      f.puts %{export EC2_CERT="#{certificate}"}
      f.puts %{export EC2_PRIVATE_KEY="#{private_key}"}
      f.puts %{exec "$AWS_RDS_HOME/bin/rds-$1" ${@:2:$#}}
    end
    File.chmod(0700, "#{path}/heroku-rds")

    display "\nInstallation complete! Remember to add #{path} to your path if necessary."
  end

  def ingress
    check_dependencies('heroku-rds')
    security_group = args.shift || 'default'

    exec *%W{heroku-rds authorize-db-security-group-ingress #{security_group} --cidr-ip #{current_ip}/32}
  end

  def revoke
    check_dependencies('heroku-rds')
    while arg = args.shift
      if arg =~ /^(?:\d{1,3}\.){3}\d{1,3}$/
        ip = arg
      else
        security_group = arg
      end
    end
    ip ||= current_ip
    security_group ||= 'default'

    exec *%W{heroku-rds revoke-db-security-group-ingress #{security_group} --cidr-ip #{ip}/32}
  end

  def access
    check_dependencies('heroku-rds')
    exec *%W{heroku-rds describe-db-security-groups}
  end

  def pull
    check_dependencies('mysqldump', 'mysql')

    target = args.shift || 'development'
    if target =~ %r{://}
      target = URI.parse(target)
      validate_db(target)
      target = uri_to_hash(target)
    else
      raise CommandFailed, "config/database.yml not found" unless File.readable?("config/database.yml")
      db_config = YAML.load(File.open("config/database.yml"))
      raise CommandFailed, "environment #{target.inspect} not found in config/database.yml" unless
        db_config.has_key?(target)
      validate_db(db_config[target], target)
      target = db_config[target]
    end

    display "This will erase all data in the #{target['database'].inspect} database" +
      (target['host'].empty? ? '' : " on #{target['host']}") + "!"
    exit unless ask("Are you sure you wish to continue? [yN] ").downcase == 'y'

    exec('/bin/sh', '-c',
         'mysqldump --compress --single-transaction ' + args_to_s(mysql_args(database_uri)) +
         pv_pipe +
         %{| mysql --compress } + args_to_s(mysql_args(target)))
  end

  private

  def current_ip
    # simple rack app which returns your external IP
    RestClient::Resource.new("http://ip4.heroku.com")['/'].get.strip
  end

  def ask(prompt = nil)
    Readline.readline(prompt)
  end

  def parse_database_uri
    URI.parse(heroku.config_vars(app)['DATABASE_URL'])
  end

  def mysql_args(creds)
    creds = uri_to_hash(creds) if creds.is_a?(URI)
    args = []
    args.concat(['-u', creds['username']]) if creds['username'] && !creds['username'].empty?
    args << "-p#{creds['password']}" if creds['password'] && !creds['password'].empty?
    args.concat(['-h', creds['host']]) if creds['host'] && !creds['host'].empty?
    args.concat(['-P', creds['port']]) if creds['port'] && !creds['port'].empty?
    args.concat(['-S', creds['socket']]) if creds['socket'] && !creds['socket'].empty?
    args << creds['database']
    args
  end

  def args_to_s(args)
    "'" + args.collect { |s| s.gsub("'", "\\'") }.join("' '") + "'"
  end

  def exec(*args)
    ENV['DEBUG'] ? puts("exec(): #{args.inspect}") && exit : super
  end

  def system(*args)
    exec = ENV['DEBUG'].nil?
    unless exec
      puts("system(): #{args.inspect}")
      exec = ask("execute? [yN] ") == 'y'
    end
    if exec
      super or raise CommandFailed, "command failed [code=#{$?.exitstatus}]: " + args.join(' ')
    end
  end

  def validate_db(creds, name = nil)
    if creds.is_a?(URI)
      raise CommandFailed, "#{name || creds.to_s} is not a MySQL server" unless creds.scheme =~ /^mysql/
    else
      raise CommandFailed, "#{name || creds.inspect} is not a MySQL server" unless creds['adapter'] =~ /^mysql/
    end
  end

  def check_dependencies(*commands)
    options = commands.last.is_a?(Hash) ? commands.pop : {}
    results = commands.collect do |cmd|
      path = `which #{cmd}`.strip
      if !options[:optional]
        raise CommandFailed, "#{cmd}: not found in path" + (cmd == 'heroku-rds' ? ' - you may need to run "heroku rds:install_tools"' : '') if path.empty?
        raise CommandFailed, "#{cmd}: not executable" unless File.executable?(path)
      else
        !path.empty? && File.executable?(path)
      end
    end
    results.inject { |a, b| a && b }
  end

  def uri_to_hash(uri)
    { 'username' => uri.user,
      'password' => uri.password,
      'host' => uri.host,
      'port' => uri.port,
      'database' => uri.path.sub('/', '') }
  end

  def pv_installed?
    check_dependencies('pv', :optional => true)
  end

  def pv_pipe
    pv_installed? ? '| pv ' : ''
  end

end; end
