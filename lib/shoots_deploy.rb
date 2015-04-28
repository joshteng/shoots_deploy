require "shoots_deploy/version"
require "shoots_deploy/configuration"
require "shoots_deploy/hosted_zone"
require "shoots_deploy/bucket"

module ShootsDeploy
  def self.deploy
    if deployed_before?
      configuration = Configuration.initialize_from_file
      initialize_aws(region: configuration.region, secret_key: configuration.secret_key, access_key: configuration.access_key)
      bucket = Bucket.new(configuration.main_bucket_name)
      bucket.sync_site_with(Dir.pwd)
    else
      access_key = get_access_key
      secret_key = get_secret_key
      region = select_region

      configuration = Configuration.new(region: region, access_key: access_key, secret_key: secret_key)

      initialize_aws(region: configuration.region, secret_key: configuration.secret_key, access_key: configuration.access_key)

      if use_custom_domain? && use_route_53?
        configuration.root_domain = get_root_domain
        configuration.subdomain = get_subdomain
        hosted_zone = HostedZone.new(configuration)

        if use_root_domain_with_route_53?(configuration) #this also makes the root domain as the primary url to the site
          configuration.main_bucket_name = configuration.root_domain
          configuration.secondary_bucket_name = configuration.subdomain + '.' +configuration.root_domain
          configuration.subdomain_url = configuration.secondary_bucket_name

          create_configure_populate_main_bucket(configuration)

          secondary_bucket = Bucket.initialize_with_name(configuration.secondary_bucket_name)
          secondary_bucket.configuration = configuration
          secondary_bucket.redirect_traffic

          hosted_zone.configure_alias_record
          hosted_zone.configure_cname_record

        else #no root domain
          configuration.main_bucket_name = configuration.subdomain + '.' + configuration.root_domain
          configuration.subdomain_url = configuration.main_bucket_name

          create_configure_populate_main_bucket(configuration)

          hosted_zone.configure_cname_record
        end

        #prompt user to set up Route 53 as their DNS
        puts "\nSet up your domain to use the Amazon Route 53 as your DNS by changing to the following nameservers:"
        puts hosted_zone.ns_resource_records

        notify_user_of_temporary_s3_url(configuration)

      elsif use_custom_domain? #no Amazon Route 53, own DNS like cloudflare
        configuration.subdomain_url = configuration.main_bucket_name = get_url

        create_configure_populate_main_bucket(configuration)

        #prompt user to set up DNS server
        puts "\nSet up your DNS with the corresponding CNAME and point it to `#{configuration.s3_website_endpoint}`.\nIf you want your root domain to be redirected to this website, set up the necessary redirection rules."

        notify_user_of_temporary_s3_url(configuration)

      else #no custom domain
        configuration.main_bucket_name = get_site_name

        create_configure_populate_main_bucket(configuration)

        puts "\nYou can see your website at #{configuration.s3_website_endpoint}"
      end
      configuration.create_config_file
    end
  end

  #ancilliary methods
  def self.deployed_before?
    File.exist?(Dir.pwd + '/' + Configuration::CONFIG_FILE)
  end

  def self.initialize_aws(region: nil, access_key: nil, secret_key: nil)
    AWS.config(access_key_id: access_key, secret_access_key: secret_key, region: region)
  end

  def self.create_configure_populate_main_bucket(configuration, directory: Dir.pwd)
    main_bucket = Bucket.initialize_with_name(configuration.main_bucket_name)
    main_bucket.upload_files_from(directory)
    main_bucket.configure_policy
    main_bucket.configure_to_serve_website
  end

  def self.select_region
    while true
      puts "\nSelect your region eg."
      AWS.regions.to_a.each_with_index { |r, i| puts "#{i+1}. #{r.name}" }
      print "\nType the number of the region: "
      region_index = gets.chomp.to_i - 1
      selected_region = AWS.regions.map { |r| r.name }[region_index]
      print "\nYou have selected #{selected_region}.\nIs that right? (y/n): "
      confirmation = gets.chomp
      break selected_region if confirmation == 'y' #must have break because while loop returns nil with a break it returns selected_region
    end
  end

  def self.get_access_key
    access_key = ''

    while access_key.empty?
      print "\nWhat's your AWS access key? "
      access_key = gets.chomp
    end

    access_key
  end

  def self.get_secret_key
    secret_key = ''

    while secret_key.empty?
      print "\nWhat's your AWS secret key? "
      secret_key = gets.chomp
    end

    secret_key
  end

  def self.use_custom_domain?
    @custom_domain = @custom_domain || get_user_confirmation("Do you want to use a custom domain for your site? (type y/n)")
    @custom_domain == 'y'
  end

  def self.use_route_53?
    use_route_53 = get_user_confirmation("Do you want to use AWS Route 53 as your DNS provider? (type y/n)")
    use_route_53 == 'y'
  end

  def self.use_root_domain_with_route_53?(configuration)
    use_root_domain = get_user_confirmation("Do you want to use your root domain, #{configuration.root_domain} for this site? (type y/n)")
    use_root_domain == 'y'
  end

  def self.get_root_domain
    prompt = "What is your root domain? eg. example.com"
    confirmation_message = "You root domain is"
    get_user_input_with_prompt(prompt, confirmation_message: confirmation_message)
  end

  def self.get_subdomain
    prompt = "What is your preferred subdomain? eg. www or hello"
    confirmation_message = "Your preferred subdomain is"
    get_user_input_with_prompt(prompt, confirmation_message: confirmation_message)
  end

  def self.get_url
    prompt = "What will your website URL be? eg. www.example.com"
    confirmation_message = "Your website's url will be"
    get_user_input_with_prompt(prompt, confirmation_message: confirmation_message)
  end

  def self.get_site_name
    prompt = "What is the name of your site? (something unique to prevent S3 bucket name clashing)"
    confirmation_message = "Your site name is"
    get_user_input_with_prompt(prompt, confirmation_message: confirmation_message)
  end

  def self.get_user_input_with_prompt(prompt, confirmation_message: "You entered")
    while true
      print "\n#{prompt}: "
      input = gets.chomp
      print "\n#{confirmation_message} #{input}. Is that right? (y/n): "
      confirmation = gets.chomp
      break input if confirmation == 'y'
    end
  end

  def self.get_user_confirmation(prompt)
    while true
      print "\n#{prompt}: "
      input = gets.chomp
      print "\nAre you sure? (y/n): "
      confirmation = gets.chomp
      break input if confirmation == 'y'
    end
  end

  def self.notify_user_of_temporary_s3_url(configuration)
    puts "\nIn the meantime, you can see your website at #{configuration.s3_website_endpoint}"
  end
end
