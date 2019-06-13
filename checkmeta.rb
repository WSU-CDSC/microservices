#!/usr/bin/env ruby
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
output_file_path = File.expand_path("~/Desktop/monitor-archive-warnings.txt")
output_file = File.open(output_file_path,"w")
  if ! needExaminationHash.empty?
    output_file.puts "Needs Examination for hash failure!"
    output_file.puts needExaminationHash
    output_file.puts "---"
  end
  if ! needExaminationChanged.empty?
    output_file.puts "Needs Examination for file manifest changes!"
    output_file.puts needExaminationChanged
  end
  if ! newFilesInCloud.empty?
    output_file.puts 'New files detected in collections stored in cloud! Sync needed!'
    output_file.puts newFilesInCloud
  end
output_file.close
File.readlines(output_file_path).each { |line| puts line }

if (changedNoMeta.empty? && changedWithMeta.empty?)
  green("No changed directories found!")
  File.write(File.expand_path("~/Desktop/monitor-archive-warnings.txt"),"No changed directories found!")
end


# Update log times for unchanged directories
unchangedDirList = (scanDirList - changedNoMeta - changedWithMeta)
unchangedDirList.each { |target| logTimeWrite(target) }