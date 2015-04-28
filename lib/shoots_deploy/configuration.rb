require 'yaml'

class ShootsDeploy::Configuration
  attr_accessor :main_bucket_name, :secondary_bucket_name, :region, :root_domain, :subdomain, :subdomain_url, :secret_key, :access_key

  CONFIG_FILE = "shoots.yml"

  def initialize(options = {})
    @main_bucket_name = options[:main_bucket_name]
    @region = options[:region]
    @secret_key = options[:secret_key]
    @access_key = options[:access_key]
  end

  def self.initialize_from_file
    configs = YAML.load_file(CONFIG_FILE)
    new({
      main_bucket_name: configs['bucket_name'],
      region: configs['bucket_region'],
      secret_key: configs['secret_key'],
      access_key: configs['access_key']
      })
  end

  def create_config_file
    config_file = File.new(CONFIG_FILE, "w")
    config_file.puts("bucket_name: '#{main_bucket_name}'\nbucket_region: '#{region}'\naccess_key: '#{access_key}'\nsecret_key: '#{secret_key}'\n")
  end

  def s3_website_endpoint
    "#{main_bucket_name}.s3-website-#{region}.amazonaws.com"
  end
end
