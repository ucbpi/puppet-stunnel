source 'https://rubygems.org'

if ENV.key?('PUPPET_VERSION')
  puppetversion = "#{ENV['PUPPET_VERSION']}"
 else
   puppetversion = "~> 2.7.0"
end

gem 'rake'
gem 'puppet-lint'
gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
gem 'puppet', puppetversion
gem 'puppetlabs_spec_helper'
# pin rspec to < 3.0.0 until rspec-puppet supports rspec > 3.0.0
# https://github.com/rodjek/rspec-puppet/issues/200
gem 'rspec', '~> 2.0'
