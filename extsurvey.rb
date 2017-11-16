#!/usr/local/bin/ruby
require 'csv'
require 'os'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: extensionsurvey.rb [option] [inputdirectory1] [inputdirectory2]..."

  opts.on('-r', '--record threshold', "Record file paths for all extensions under a certain threshold") do |threshold|
    options[:threshold] = threshold;
  end
    opts.on('-e', '--extension paths', "Record file paths for a certain extension") do |paths|
    options[:paths] = paths;
  end
  opts.on("-h", "--help", "Help") do
    puts opts
    exit
  end
  if ARGV.empty?
    puts opts
  end
end.parse!

# Methods for colored text output
def red(input)
  puts "\e[31m#{input}\e[0m"
end

def green(input)
  puts "\e[36m#{input}\e[0m"
end

TargetList = Array.new
Extensions = Array.new
CompleteFileList = Array.new
LowCount = Array.new

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
CSV.open("file_extensions.csv", "wb") do |csv|
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
  CompleteFileList.each do |path|
    LowCount.each do |extension|
      if path.force_encoding('utf-8').include?(extension)
        if OS.windows?
          pathlist << path.gsub("/", "\\")
        else
          pathlist << path
        end
      end
    end
  end
  File.open('filepaths.txt', 'w') do |f|
    pathlist.each do |write|
      f.puts write
    end
  end
end

#Option for writing file of paths for selected extension
if options[:paths]
  extensionpaths = Array.new
  CompleteFileList.each do |path|
    if path.force_encoding('utf-8').include?(options[:paths])
      if OS.windows?
        extensionpaths << path.gsub("/", "\\")
      else
        extensionpaths << path
      end
    end
  end
  File.open('extensionpaths.txt', 'w') do |f|
    extensionpaths.each do |write|
      f.puts write
    end
  end
end



