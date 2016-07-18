source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
   puppetversion = "#{ENV['PUPPET_VERSION']}"
 else
   puppetversion = "~> 3.8.0"
end

# pin rake to this version for as long as we need to test against
# ruby 1.8.7
gem 'rake', '10.5.0'
gem 'puppet-lint'
gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper'
# pin rspec to < 3.0.0 until rspec-puppet supports rspec > 3.0.0
# https://github.com/rodjek/rspec-puppet/issues/200
gem 'rspec', '~> 2.0'

if RUBY_VERSION == '1.8.7'
  gem 'json_pure', "1.8.3"
end
