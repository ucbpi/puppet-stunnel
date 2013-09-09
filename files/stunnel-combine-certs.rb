#!/usr/bin/env ruby

require 'optparse'
require 'tempfile'
require 'fileutils'


#
## Setup Some Option Parsing
options = {}

USAGE_NAME = File.basename($0)


optparse = OptionParser.new do |opts|
  opts.banner = "usage: #{USAGE_NAME} -c <cert path> [-c <cert path>, ...] -o <output path> [options]"
  opts.on("-c", "--cert-component PATH", "certificate component to add to the combined cert") do |c|
    options[:components] = Array.new() unless options[:components].is_a?(Array)
    options[:components].push(c)
  end

  opts.on("-o", "--output PATH", "output of combined cert") do |o|
    options[:output] = o
  end

  opts.on("-f", "--force", "force overwrite of cert if one already exists") do |f|
    options[:force] = f
  end

  opts.on("-t", "--test", "test if combined cert is same as existing cert",
                          "if files are similar, RC=0. Otherwise, RC=1") do |t|
    options[:test] = t
  end
end

begin
  optparse.parse!
rescue OptionParser::ParseError => e
  puts e.to_s
  puts "\n"
  puts optparse.to_s
  exit 1
end

if ! options[:output] or ! options[:components]
  puts "You must specify both an output certificate (-o) and at least one cert component (-c)"
  puts "\n#{optparse.to_s}"
  exit 1
end


#
## Validate Our Options
begin
  options[:components].each do |c|
    raise "Certificate File '#{c}' does not exist!" unless File.exist?(c)
  end
rescue NoMethodError => e
  puts "You must specify at least one certificate component (-c)"
  exit  1
rescue RuntimeError => e
  puts e
  exit 1
end

ok = nil
begin
  ok = File.readable?(options[:output]) if options[:test] and options[:output]
  ok = File.new(options[:output], "w") unless options[:test] or options[:output]
rescue Errno::EACCES => e
  puts "Unable to access '#{options[:output]}'"
end

#
## Build Out the Cert File
output_exists = File.exist?(options[:output])
tmp_out = Tempfile.new('concat-stunnel-cert-')
options[:components].each do |c|
  c_in = File.open( c, 'r')
  c_in.each { |c_in_s| tmp_out.puts(c_in_s)}
  c_in.close
end
tmp_out.close

files_differ = true if ! output_exists or \
  FileUtils.compare_file(tmp_out.path, options[:output]) == false

if options[:test]
  exit 0 unless files_differ
  exit 1
end

if output_exists and files_differ
  # if the file exists, and they are different, we'll copy it if we're forced to
  FileUtils.cp(tmp_out.path, options[:output]) if options[:force]
elsif files_differ
  FileUtils.cp(tmp_out.path, options[:output])
else
  # file exists and is the same, so we do nothing
end

tmp_out.unlink
exit 0
