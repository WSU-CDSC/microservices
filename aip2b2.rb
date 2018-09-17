#!/usr/bin/env ruby
require "pathname"
require 'json'
require 'optparse'

ARGV.options do |opts|
  opts.on("-d", "--dry-run")  { $dryrun = '--dryRun ' }
  opts.on("-p", "--path=val", String)  { |val| $b2path = val }
  opts.parse!
end

# Set up methods
def premisreport(actiontype,outcome)
   @premis_structure['events'] << [{'eventType':actiontype,'eventDetail':$command,'eventDateTime':Time.now,'eventOutcome':outcome}] 
end

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end
end

# Check for b2 path
if $b2path.nil?
  puts "Please enter a B2 path using the -p flag.".red
  exit
end

ARGV.each do |input_AIP|
  @target_path = Pathname.new(input_AIP)
  # Test for directory
  if ! @target_path.directory?
    puts "Input must be a directory! Exiting.".red && exit
  end
  packagename = File.basename(@target_path)
  b2_target = $b2path + '/' + packagename
  logfile = @target_path + 'data' + 'logs' + "#{packagename}.log"
  @premis_structure = JSON.parse(File.read(logfile))
  if $dryrun.nil?
   $command = 'b2 sync ' + '"' + @target_path.to_s + '" ' + '"' + b2_target + '"'
  else
    $command = 'b2 sync ' + $dryrun + '"' + @target_path.to_s + '" ' + '"' + b2_target + '"'
  end

  if system($command)
    puts "SUCCESS!".green
    premisreport('replication','pass')
    puts @premis_structure
    if $dryrun.nil?
      File.open("#{@target_path.to_s}/#{packagename}_#{Time.now}_premis.log",'w') {|file| file.write(@premis_structure.to_json)}
      system($command)
    end
  end
end
