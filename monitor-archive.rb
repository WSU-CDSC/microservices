#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))

require "#{scriptLocation}/wsu-functions.rb"

#Start of script process

watchDir = ARGV[0]
scanDirList = Dir.glob("#{watchDir}/*")
changedDirs = Array.new
changedWithMeta = Array.new
changedNoMeta = Array.new
needExamination = Array.new

scanDirList.each do |scanDir|
  logTimeRead(scanDir)
  if (File.mtime(scanDir) - @priorRunTime) > 10
    changedDirs << scanDir
  end
end

changedDirs.each do |checkForMetadata|
  metaDir = "#{checkForMetadata}/metadata"
  md5Base = File.basename(checkForMetadata) + '.md5'
  md5File = "#{metaDir}/#{md5Base}"
  if ! File.exist?(metaDir)
    changedNoMeta << checkForMetadata
  elsif ! File.exist?(md5File)
    changedNoMeta << checkForMetadata
  elsif File.mtime(metaDir) < File.mtime(checkForMetadata)
    changedWithMeta << checkForMetadata
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
    if @missingFiles.empty? &&  @fixityCheck != 'fail'
      logTimeWrite(target)
    else
      needExamination << target
    end
  end
  puts "Needs Examination!"
  puts needExamination
  File.write(File.expand_path("~/Desktop/monitor-archive-warnings.txt"),needExamination)
end

# Update log times for unchanged directories
unchangedDirList = (scanDirList - changedNoMeta - changedWithMeta)
unchangedDirList.each { |target| logTimeWrite(target) }