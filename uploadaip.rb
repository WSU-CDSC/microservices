#!/usr/bin/env ruby

require "pathname"
require 'json'
require 'optparse'
scriptLocation = File.expand_path(File.dirname(__FILE__))
require "#{scriptLocation}/wsu-functions.rb"
$b2_delete = ''
$dryrun = ''

CheckDependencies(['b2'])


ARGV.options do |opts|
  opts.on("-d", "--dry-run")  { $dryrun = ' --dryRun ' }
  opts.on("-x", "--delete")  { $b2_delete = ' --delete ' }
  opts.on("-p", "--path=val", String)  { |val| $b2path = val }
  opts.parse!
end

# Set up methods

def outcomereport(target)
  outcome_log = ENV['HOME'] + "/Desktop/aip2_B2_OUTCOME_LOG.txt"
  open(outcome_log, "a") do |l|
    l.puts ''
    l.puts "Package: #{target}\n"
      targetDir = File.expand_path(target)
      baseName = File.basename(targetDir)
      metadata_dir = "#{targetDir}/metadata"
      premisLog = "#{metadata_dir}/#{baseName}_PREMIS.log"
      log = JSON.parse(File.read(premisLog))
      l.puts log['events'].last['eventDetail']
      l.puts log['events'].last['eventOutcome']
      l.puts ''
  end
end

# Check for b2 path
if $b2path.nil?
  puts red("Please enter a B2 path using the -p flag.")
  exit
end

ARGV.each do |input_AIP|
  @target_path = Pathname.new(input_AIP)
  # Test for directory
  if ! @target_path.directory?
    puts red("Input must be a directory! Exiting.") && exit
  end
  $packagename = File.basename(@target_path)
  @targetdir = File.dirname(@target_path)
  b2_target = $b2path + '/' + $packagename
  logfile = @target_path + 'data' + 'logs' + "#{$packagename}.log"
  if File.exist?(logfile)
    @premis_structure = JSON.parse(File.read(logfile))
  end

   $command = 'b2 sync ' + $dryrun + $b2_delete + '"' + @target_path.to_s + '" ' + '"' + b2_target + '"'

  if system($command)
    green("SUCCESS!")
    if $dryrun.empty?
      log_premis_pass(input_AIP,'aip2b2.rb')
      system($command)
      outcomereport(input_AIP)
    end
  else
    red("FAIL!")
    red("Retrying...")
    unless system($command)
      if $dryrun.empty?
        red("FAIL!")
        log_premis_fail(input_AIP,'aip2b2.rb')
        outcomereport(input_AIP)
      end
    else
      green("SUCCESS!")
      if $dryrun.empty?
        log_premis_pass(input_AIP,'aip2b2.rb')
        system($command)
        outcomereport(input_AIP)
      end
    end
  end
end
