#!/usr/local/bin/ruby
require 'csv'
require 'os'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: extensionsurvey.rb [option] [inputdirectory1] [inputdirectory2]..."

  opts.on('-t', '--threshold threshold', "Record file paths for all extensions under a certain threshold") do |threshold|
    options[:threshold] = threshold;
  end
    opts.on('-e', '--extension paths', "Record file paths for a certain extension") do |paths|
    options[:paths] = paths;
  end
  opts.on('-a', '--all', "Record all file paths") do |all|
    options[:all] = 'all';
  end
  opts.on("-h", "--help", "Help") do
    puts opts
    exit
  end
  if ARGV.empty?
    puts opts
    exit
  end
end.parse!

# Methods for colored text output
def red(input)
  puts "\e[31m#{input}\e[0m"
end

def green(input)
  puts "\e[36m#{input}\e[0m"
end

# Get path to Desktop for output
if OS.windows?
  Desktop = ENV['HOME'] + '\\Desktop\\'
else
  Desktop = ENV['HOME'] + '/Desktop/'
end

TargetList = Array.new
Extensions = Array.new
CompleteFileList = Array.new
LowCount = Array.new
runtime = Time.now.strftime("%Y%m%d_%H%M%S")

def normalize(normalized)
  normalized = normalized.downcase
  if normalized == '.jpeg'
    normalized = '.jpg'
  elsif normalized == '.tiff'
    normalized = '.tif'
  end
  return normalized
end

Sanitize = ['Thumbs.db']


ARGV.each do |target|
  if OS.windows?
    target = target.gsub("\\", "/")
  end
  TargetList << "#{target}/**/*"
end

TargetList.each do |target|
  green("Getting file list for: #{target}")
  fileList = Dir.glob(target)
  fileList.each do |file|
    if ! Sanitize.include? File.basename(file)
      CompleteFileList << file
    end
  end
end

CompleteFileList.each do |path|
  extension = normalize(File.extname(path))
  if ! extension.empty?
    Extensions << extension
  end
end


uniqueextensions = Extensions.uniq.sort
Extensionlist = Array.new
writetarget = Desktop + runtime + '_file_extensions.csv'
CSV.open(writetarget, "wb") do |csv|
  csv << ["count", "Extension"]
  uniqueextensions.each do |unique|
    count = Extensions.count(unique)
    if options[:threshold] && count < Integer(options[:threshold])
      LowCount << unique
    end
    csv << [count, unique]
  end
end

#Option for writing file of paths for extensions under a certain count
if options[:threshold]
  pathlist = Array.new
  writetarget = Desktop + runtime + '_threshold_filepaths.txt'
  CompleteFileList.each do |path|
    pathextension = File.extname(path)
    LowCount.each do |extension|
      if pathextension.force_encoding('utf-8') == extension
        if OS.windows?
          pathlist << path.gsub("/", "\\")
        else
          pathlist << path
        end
      end
    end
  end
  File.open(writetarget, 'w') do |f|
    pathlist.each do |write|
      f.puts write
    end
  end
end

#Option for writing file of paths for selected extension
if options[:paths]
  extensionpaths = Array.new
  writetarget = Desktop + runtime + '_extension_filepaths.txt'
  CompleteFileList.each do |path|
    if path.force_encoding('utf-8').include?(options[:paths])
      if OS.windows?
        extensionpaths << path.gsub("/", "\\")
      else
        extensionpaths << path
      end
    end
  end
  File.open(writetarget, 'w') do |f|
    extensionpaths.each do |write|
      f.puts write
    end
  end
end

#Option for writing all paths
if options[:all]
  extensionpaths = Array.new
  writetarget = Desktop + runtime + '_all_filepaths.txt'
  File.open(writetarget, 'w') do |f|
    CompleteFileList.each do |write|
      f.puts write
    end
  end
end



