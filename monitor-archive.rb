#!/usr/bin/env ruby
scriptLocation = File.expand_path(File.dirname(__FILE__))

require "#{scriptLocation}/wsu-functions.rb"

#Start of script process

watchDir = ARGV[0]
scanDirList = Dir.glob("#{watchDir}/*").select { |target| File.directory?(target) }
changedDirs = Array.new
changedWithMeta = Array.new
changedNoMeta = Array.new
needExaminationHash = Array.new
needExaminationChanged = Array.new

scanDirList.each do |scanDir|
  logTimeRead(scanDir)
  if (File.mtime(scanDir) - @priorRunTime) > 10
    changedDirs << scanDir
  else
    subDirs = Dir.glob("#{scanDir}/**/*").select { |target| File.directory?(target) }
    subDirs.each do |scanSubDir|
      if (File.mtime(scanSubDir) - @priorRunTime) > 10
        changedDirs << scanDir
      end
    end
  end
end

puts changedDirs

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

if changedDirs.empty?
  green("No changed directories found!")
  File.write(File.expand_path("~/Desktop/monitor-archive-warnings.txt"),"No changed directories found!")
end


# Update log times for unchanged directories
unchangedDirList = (scanDirList - changedNoMeta - changedWithMeta)
unchangedDirList.each { |target| logTimeWrite(target) }