#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))

require "#{scriptLocation}/wsu-functions.rb"
require 'set'
require 'optparse'

scanDirList = Set[]

ARGV.options do |opts|
  opts.on("-t", "--target=val", String)  { |val| scanDirList << val }
  opts.parse!
end

#Start of script process
if scanDirList.empty?
  scanDirList = Dir.glob("#{ARGV[0]}/*").select { |target| File.directory?(target) }.to_set
  scanDirList.reject! { |dir_name| File.basename(dir_name).include?('Unprocessed') }
end
changedWithMeta = Set[]
changedNoMeta = Set[]
needExaminationHash = []
needExaminationChanged = []

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
    CompareContents(target)
    if (@noChange = 'true' &&  @fixityCheck == 'pass')
      logTimeWrite(target)
      @noChange = ''
      @fixityCheck = ''
    elsif @fixityCheck == 'fail'
      needExaminationHash << target
      @fixityCheck = ''
    else
      needExaminationChanged << target
    end
  end
  if ! needExaminationHash.empty?
    red("Needs Examination for hash failure!")
    puts needExaminationHash
    puts "---"
  end
  if ! needExaminationChanged.empty?
    red("Needs Examination for file manifest changes!")
    puts needExaminationChanged
  end
  File.write(File.expand_path("~/Desktop/monitor-archive-warnings.txt"),(needExaminationHash + needExaminationChanged))   
end

if (changedNoMeta.empty? && changedWithMeta.empty?)
  green("No changed directories found!")
  File.write(File.expand_path("~/Desktop/monitor-archive-warnings.txt"),"No changed directories found!")
end


# Update log times for unchanged directories
unchangedDirList = (scanDirList - changedNoMeta - changedWithMeta)
unchangedDirList.each { |target| logTimeWrite(target) }