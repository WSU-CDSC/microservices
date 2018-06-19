#!/usr/bin/env ruby

require 'os'
require 'yaml'
require 'optparse'

#Enter Location of Configuration File between the single quotes In this section!!
########
configuration_file = '' 
########

# Confirm and set config
path2script = __dir__
DefaultConfigLocation = "#{path2script}/wsumetaedit_config.txt"
if configuration_file.empty?
	configuration_file = DefaultConfigLocation
end

if ! File.exist? configuration_file
	puts "Selected configuration file not found. Exiting"
	exit
end

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options] [inputfile1] [inputfile2] ..."

  opts.on("-e", "--edit", "Edit Mode") do |e|
    options[:edit] = 'edit'
  end
  opts.on("-h", "--help", "Help") do
    puts opts
    exit
  end
  if ARGV.empty?
    puts opts
  end
end.parse!

if options[:edit] == 'edit'
  if OS.windows?
    system("start #{configuration_file}")
    exit
  elsif OS.linux?
    system("xdg-open '#{configuration_file}' || nano '#{configuration_file}'")
    exit
  elsif OS.mac?
    system("open '#{configuration_file}' || nano '#{configuration_file}'")
    exit
  end
end

config = YAML::load_file(configuration_file)
Originator = config['Originator']
History = config['Coding History']

if Originator.length > 32
  puts "Value for Originator must be under 32 characters. Please check your configurations."
  exit
end


#Check for bwfmetaedit
if OS.windows?
  DefaultbwfmetaeditLocation = "#{path2script}/bwfmetaedit.exe"
  if ! system('bwfmetaedit.exe -h', [:out, :err] => File::NULL) && ! File.exist?(DefaultbwfmetaeditLocation)
    puts "Required program bwfmetaedit not found. Please see installation information at http://md5deep.sourceforge.net/start-hashdeep.html"
    exit
elsif ! system('bwfmetaedit.exe -h', [:out, :err] => File::NULL) && File.exist?(DefaultbwfmetaeditLocation)
  bwfmetaeditpath = DefaultbwfmetaeditLocation
  else
    bwfmetaeditpath = 'bwfmetaedit.exe'
  end
else

  if ! system('bwfmetaedit -h', [:out, :err] => File::NULL)
    puts "Required program bwfmetaedit not found. Please see installation information at https://mediaarea.net/BWFMetaEdit"
    exit
  else
    bwfmetaeditpath = 'bwfmetaedit'
  end
end

# Loop for embedding

ARGV.each do|file_input|
  # Check for valid input
  if File.extname(file_input).downcase != '.wav'
    puts "Input file is not a WAV file. Skipping."
    next
  elsif ! File.exist?(file_input)
    puts "Input file not found. Skipping."
    next
  end

  # Get File Modification Time for OriginationDate and OriginationTime
  moddatetime = File.mtime(file_input)
  moddate = moddatetime.strftime("%Y-%m-%d")
  modtime = moddatetime.strftime("%H:%M:%S")

  #Get Input Name for Description and OriginatorReference
  file_name = File.basename(file_input)
  originatorreference = File.basename(file_input, '.wav')
  if originatorreference.length > 32
    originatorreference = "See Description for Identifiers"
  end


  # Check sytstem and execute BWF Metaedit
  if OS.windows? 
    command = %{#{bwfmetaeditpath} --reject-overwrite  --Description="#{file_name}" --Originator="#{Originator}" --OriginatorReference="#{originatorreference}" --History="#{History}" --IARL="#{Originator}" --OriginationDate="#{moddate}" --OriginationTime="#{modtime}" --MD5-Embed "#{file_input}"}
  else
    command = "#{bwfmetaeditpath} --reject-overwrite  --Description='#{file_name}' --Originator='#{Originator}' --OriginatorReference='#{originatorreference}' --History='#{History}' --IARL='#{Originator}' --OriginationDate='#{moddate}' --OriginationTime='#{modtime}' --MD5-Embed '#{file_input}'"
    puts command
  end
  puts "Processing file: #{file_input}"
  system(command)
end
