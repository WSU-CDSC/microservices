#!/usr/bin/env ruby
begin
scriptLocation = File.expand_path(File.dirname(__FILE__))

require "#{scriptLocation}/wsu-functions.rb"
require 'set'
require 'optparse'

# Check for dependencies
CheckDependencies(['mediainfo','exiftool','hashdeep'])

scanDirList = Set[]
ignoreDirList = Set[]

ARGV.options do |opts|
  opts.on("-t", "--target=val", String)  { |val| scanDirList << val }
  opts.on("-x", "--ignore=val", String)  { |val| ignoreDirList << val }
  opts.parse!
end

#Start of script process
if scanDirList.empty?
  scanDirList = Dir.glob("#{ARGV[0]}/*").select { |target| File.directory?(target) }.to_set
  scanDirList.reject! { |dir_name| File.basename(dir_name).include?('Unprocessed') }
end

#remove directories flagged as 'ignore'
unless ignoreDirList.empty?
  scanDirList = (scanDirList - ignoreDirList)
end

changedWithMeta = Set[]
changedNoMeta = Set[]
needExaminationHash = []
needExaminationChanged = []
newFilesInCloud = []
addedMeta = []

scanDirList.each do |scanDir|
  metaDir = "#{scanDir}/metadata"
  md5Base = File.basename(scanDir) + '.md5'
  md5File = "#{metaDir}/#{md5Base}"
  logTimeRead(scanDir)
  dirList =  Dir.glob("#{scanDir}/**/*").select { |target| File.directory?(target) }
  dirList << scanDir
  dirList.each do |dir|
    if (File.mtime(dir) - @priorRunTime) > 10
      if (! File.exist?(metaDir) || ! File.exist?(md5File))
        changedNoMeta << scanDir
      elsif File.mtime(metaDir) < File.mtime(dir)
        changedWithMeta << scanDir
      end
    end
  end
end

unless changedNoMeta.empty?
  green("Missing metadata found in the following directories:")
  changedNoMeta.each { |dir| puts dir }
  puts "----"
end
unless changedWithMeta.empty?
  green("Changed directories found:")
  changedWithMeta.each { |dir| puts dir }
  puts "----"
end

if ! changedNoMeta.empty?
  red("Directories found that do not contain metadata")
  purple("Will generate metadata")
  changedNoMeta.each do |needsMeta|
    green("Generating metadata for: #{needsMeta}")
    CleanUpMeta(needsMeta)
    logTimeWrite(needsMeta)
    addedMeta << [needsMeta]
  end
end

if ! changedWithMeta.empty?
  changedWithMeta.each do |target|
    contents_comparison = CompareContents(target)
    if (contents_comparison[0] == 'no change' &&  contents_comparison[1] == 'pass')
      logTimeWrite(target)
    elsif contents_comparison[0] == 'new files' && contents_comparison[1] == 'pass'
      green("New files detected - will update metadata")
      CleanUpMeta(target)
      logTimeWrite(target)
      cloud_check = check_cloud_status(target)
      if cloud_check == 1
        cloud_status = "WARNING IN CLOUD"
        newFilesInCloud << [target]
      else
        addedMeta << [target]
      end
    elsif contents_comparison[1] == 'fail'
      red("Fixity failure detected!")
      cloud_check = check_cloud_status(target)
      if cloud_check == 1
        cloud_status = "WARNING IN CLOUD"
      else
        cloud_status = ''
      end
      needExaminationHash << [target,contents_comparison[2],cloud_status]
    else
      red("Manifest changes detected!")
      cloud_check = check_cloud_status(target)
      if cloud_check == 1
        cloud_status = "WARNING IN CLOUD"
      else
        cloud_status = ''
      end
      needExaminationChanged << ["-- Package name:",target, "-- Missing Files:", contents_comparison[1], "-- New Files:", contents_comparison[2], "-- Cloud Status:", cloud_status, "\n"]
    end
  end
end
puts ''
puts '----'
if File.exist?(Meta_check_log_path)
  output_file_path = "#{Meta_check_log_path}/monitor-archive-warnings_#{Time.now.strftime("%Y-%m-%d%H%M%S")}.txt"
else
  output_file_path = "#{ENV['HOME']}/monitor-archive-warnings_#{Time.now.strftime("%Y-%m-%d%H%M%S")}.txt"
end
output_file = File.open(output_file_path,"w")
  if ! needExaminationHash.empty?
    output_file.puts 'Needs Examination for hash failure!'
    output_file.puts needExaminationHash
    output_file.puts '---'
  end
  if ! needExaminationChanged.empty?
    output_file.puts 'Needs Examination for file manifest changes!'
    output_file.puts needExaminationChanged
  end
  if ! addedMeta.empty?
    output_file.puts 'Metadata added/modified in the following targets!'
    output_file.puts addedMeta
  end
  if ! newFilesInCloud.empty?
    output_file.puts 'New files detected in collections stored in cloud! Sync needed!'
    output_file.puts newFilesInCloud
  end
output_file.close
File.readlines(output_file_path).each { |line| puts line }

if (changedNoMeta.empty? && changedWithMeta.empty?) || 
  green("No changed directories found!")
  File.write(output_file_path,"No changed directories found!")
end

green("Emailing log file")
sendMail(output_file_path,Email_targets)


# Update log times for unchanged directories
unchangedDirList = (scanDirList - changedNoMeta - changedWithMeta)
unchangedDirList.each { |target| logTimeWrite(target) }

rescue
  puts "Error detected - sending warning to #{Email_targets}"
  sendMailError(Email_targets)
end