require 'aws-sdk'

class ShootsDeploy::Bucket
  attr_accessor :configuration

  def initialize(bucket_name)
    @name = bucket_name
    s3 = AWS::S3.new
    @s3_bucket = s3.buckets[bucket_name]
  end

  def self.initialize_with_name(bucket_name)
    puts "\nCreating bucket with name #{bucket_name}"
    s3 = AWS::S3.new
    s3.buckets.create(bucket_name)
    new(bucket_name)
  end

  def configure_policy
    @s3_bucket.policy = AWS::S3::Policy.from_json("{\"Version\":\"2008-10-17\",\"Id\":\"d1b38dd800704a01924bef9a0b40f05f\",\"Statement\":[{\"Sid\":\"Allow Public Access to All Objects\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"*\"]},\"Resource\":[\"arn:aws:s3:::#{@name}/*\"],\"Action\":[\"s3:GetObject\"]}]}")
  end

  def configure_to_serve_website
    print "\nWhat is your index document? eg. index.html or home.html: "
    index_document = gets.chomp
    index_document = index_document.empty? ? 'index.html' : index_document

    print "\nWhat is your error document? eg. 404.html or error.html: "
    error_document = gets.chomp
    error_document = error_document.empty? ? '404.html' : error_document

    @s3_bucket.configure_website do |cfg|
      cfg.index_document_suffix = index_document
      cfg.error_document_key = error_document
    end
  end

  #for secondary buckets
  def redirect_traffic
    puts "\nRedirecting secondary bucket's traffic to #{configuration.root_domain}"
    @s3_bucket.website_configuration = AWS::S3::WebsiteConfiguration.new(redirect_all_requests_to: { host_name: configuration.root_domain })
  end

  def upload_files_from(folder_absolute_path)
    puts "\nUploading all files in #{folder_absolute_path}"
    Dir.glob(folder_absolute_path + '/**/**') do |file|
      next if File.directory?(file)
      configuration_file_regex = "#{ShootsDeploy::Configuration::CONFIG_FILE}"
      configuration_file_regex = Regexp.new(configuration_file_regex)
      next if file.match(configuration_file_regex)

      folder_absolute_path_regex = folder_absolute_path + "/"
      file_relative_path = file.gsub(folder_absolute_path_regex, '')
      puts "Uploading #{file_relative_path}....."
      obj = @s3_bucket.objects[file_relative_path]
      obj.write(Pathname.new(file))
    end

    puts "\nFinish uploading!"
  end

  def sync_site_with(folder_absolute_path)
    puts "\nDeleting old files..."
    @s3_bucket.clear!
    puts "\nUploading new files..."
    upload_files_from(folder_absolute_path)
    puts "\nSite updated!"
  end
end
