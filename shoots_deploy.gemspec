# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shoots_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "shoots_deploy"
  spec.version       = ShootsDeploy::VERSION
  spec.authors       = ["Josh Teng"]
  spec.email         = ["joshteng@webermize.com"]
  spec.summary       = %q{Deploy static websites to Amazon S3}
  spec.description   = %q{Deploy your website to Amazon S3 within seconds easily and simply from your command line.}
  spec.homepage      = "http://joshteng.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   << 'shoots'
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'aws-sdk', '~> 1.50.0'
end
