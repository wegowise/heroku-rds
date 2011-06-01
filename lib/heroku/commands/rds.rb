require 'fog'
require 'uri'

module Heroku::Command

  # manage Amazon RDS instances
  #
  class Rds < BaseWithApp

    # rds
    #
    # Opens a MySQL console connected to the current database. Ingress access
    # is required to run this command (use rds:ingress to grant access).
    #
    def index
      check_dependencies('mysql')
      exec *(['mysql', '--compress'] + mysql_args(database_uri))
    end

    # rds:dump [FILE]
    #
    # Download a database dump, bzipped and saved locally
    #
    # -f, --force    # allow overwriting existing file
    #
    # if no FILE is specified, appname-date.sql.bz2 is used by default.
    # if name of FILE does not end in .sql.bz2, it will be added automatically.
    #
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

      if File.exists?(options[:filename]) && !options[:force]
        raise CommandFailed, "file already exists. use --force to override."
      end

      exec('/bin/sh', '-c',
           "mysqldump --compress --single-transaction #{args_to_s(mysql_args(database_uri))}" +
           pv_pipe +
           %{| bzip2 > '#{options[:filename]}'})
    end

    # rds:ingress [IP] [SECURITY GROUP]
    #
    # Authorize ingress access to a particular IP
    #
    # * if IP is not specified, your current IP will be used
    # * if SECURITY GROUP is not specified, 'default' will be used
    # * IP can also be a CIDR range
    #
    def ingress
      ip, security_group = parse_security_group_and_ip_from_args
      rds.authorize_db_security_group_ingress(security_group, 'CIDRIP' => ip)
      self.access
    end

    # rds:revoke [IP] [SECURITY GROUP]
    #
    # Revokes previously-granted ingress access from a particular IP
    #
    # * if IP is not specified, your current IP will be used
    # * if SECURITY GROUP is not specified, 'default' will be used
    # * IP can also be a CIDR range
    #
    def revoke
      ip, security_group = parse_security_group_and_ip_from_args
      rds.revoke_db_security_group_ingress(security_group, 'CIDRIP' => ip)
      self.access
    end

    # rds:access
    #
    # displays current ingress access settings
    #
    def access
      data = rds.security_groups.all.map do |group|
        group.ec2_security_groups.map do |group_access|
          [group.id, group_access['EC2SecurityGroupName'] + ' @ ' + group_access['EC2SecurityGroupOwnerId'], group_access['Status']]
        end +
        group.ip_ranges.map do |ip_range|
          [group.id, ip_range['CIDRIP'], ip_range['Status']]
        end
      end.flatten(1)
      data.unshift ['SECURITY GROUP', 'IP RANGE / SECURITY GROUP', 'STATUS']
      lengths = (0..2).map { |i| data.map { |d| d[i].length }.max }
      puts data.map { |d| '%-*s  %-*s  %-*s' % [lengths[0], d[0], lengths[1], d[1], lengths[2], d[2]] }.join("\n")
    end

    # rds:pull [RAILS_ENV or DATABASE_URL]
    #
    # downloads the remote database into a local database
    #
    # If a RAILS_ENV or DATABASE_URL is not specified, the current development environment
    # is used (as read from config/database.yml). This command will confirm before executing
    # the transfer.
    #
    def pull
      check_dependencies('mysqldump', 'mysql')

      target = args.shift || 'development'
      if target =~ %r{://}
        target = uri_to_hash(validate_db(URI.parse(target)))
      else
        raise CommandFailed, "config/database.yml not found" unless File.readable?("config/database.yml")
        db_config = YAML.load(File.open("config/database.yml"))
        raise CommandFailed, "environment #{target.inspect} not found in config/database.yml" unless
        db_config.has_key?(target)
        target = validate_db(db_config[target], target)
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
      creds
    end

    def check_dependencies(*commands)
      options = commands.last.is_a?(Hash) ? commands.pop : {}
      results = commands.collect do |cmd|
        path = `which #{cmd}`.strip
        if !options[:optional]
          raise CommandFailed, "#{cmd}: not found in path" if path.empty?
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

    def database_uri
      @database_uri ||= validate_db(parse_database_uri)
    end

    def aws_access_key_id
      @aws_access_key_id ||= read_or_prompt_git_config('herokurds.accessKeyID', 'Please enter your AWS Access Key ID: ', 20)
    end

    def aws_secret_access_key
      @aws_secret_access_key ||= read_or_prompt_git_config('herokurds.secretAccessKey', 'Please enter your AWS Secret Access Key: ', 40)
    end

    def read_or_prompt_git_config(config_var, prompt, length)
      value = `git config #{config_var}`.strip
      if value.empty?
        value = ask(prompt)
        unless value.length == length
          puts "That is not valid; the value should be #{length} characters long."
          return read_or_prompt_git_config(config_var, prompt, length)
        end
        system('git', 'config', '--add', config_var, value)
      end
      value
    end

    def rds
      @rds ||= RdsProxy.new(:aws_access_key_id => aws_access_key_id, :aws_secret_access_key => aws_secret_access_key)
    end

    def parse_security_group_and_ip_from_args
      ip = security_group = nil
      while arg = args.shift
        if arg =~ /^(?:\d{1,3}\.){3}\d{1,3}(?:\/\d{1,2})?$/
          raise CommandFailed, "too many arguments passed" if ip
          ip = arg
        else
          raise CommandFailed, "IP not in correct format or too many arguments passed" if security_group
          security_group = arg
        end
      end
      ip ||= current_ip + '/32'
      ip += '/32' unless ip =~ /\/\d{1,2}$/
        security_group ||= 'default'
      [ip, security_group]
    end

    class RdsProxy
      def initialize(*args)
        @instance = Fog::AWS::RDS.new(*args)
      end

      private
      def method_missing(sym, *args, &block)
        begin
          @instance.send(sym, *args, &block)
        rescue Excon::Errors::HTTPStatusError => error
          raise CommandFailed, Nokogiri::XML.parse(error.response.body).css('Message').first.content
        end
      end
    end
  end

end
