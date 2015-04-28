require 'aws-sdk'

class ShootsDeploy::HostedZone
  attr_accessor :configuration

  def initialize(configuration)
    r53 = AWS::Route53.new
    @configuration = configuration
    @hosted_zone = r53.hosted_zones.create(configuration.root_domain)
  end

  def configure_alias_record
    @hosted_zone.rrsets.create(configuration.root_domain, 'A', alias_target: {
      dns_name: "s3-website-#{configuration.region}.amazonaws.com",
      evaluate_target_health: false,
      hosted_zone_id: AWS::Route53::HostedZone::S3_HOSTED_ZONE_IDS[configuration.region]
    })
  end

  def configure_cname_record
    @hosted_zone.rrsets.create(configuration.subdomain_url, 'CNAME', :ttl => 300, :resource_records => [{:value => "#{configuration.subdomain_url}.s3-website-#{configuration.region}.amazonaws.com"}])

  end

  def transfer_existing_dns_settings
    puts "pending implementation"
  end

  def ns_resource_records
    @hosted_zone.resource_record_sets.to_a.reject { |r| r.type != 'NS' }[0].resource_records.map { |v| v[:value].gsub(/[.]$/, '') }
  end
end
